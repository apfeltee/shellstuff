#!/usr/bin/ruby

=begin
the algo in this script is pretty simple, and any programmer worth their salt should
have no issue translating this into something other than ruby.
i wrote it, used it once, now it exists, and i don't really have any use for it.
go wild with it.
=end

require "ostruct"
require "optparse"

class IncludeFile
  attr_reader :filename, :rawmode, :mode, :isglobal, :exists, :stat, :fromheader

  def initialize(filename, mode, stat, isactuallylocal, fromheader)
    @filename = filename
    @rawmode = mode
    @stat = stat
    @fromheader = fromheader
    @exists = (@stat != nil)
    @mode = "global"
    @isglobal = true
    if (rawmode == '"') || (isactuallylocal == true) then
      @mode = "local"
      @isglobal = false
    end

  end

  def as_cpp
    quotch_begin = '<'
    quotch_end = '>'
    if not @isglobal then
      quotch_begin = '"'
      quotch_end = '"'
    end
    return ["#include ", quotch_begin, filename, quotch_end].join
  end
  
end

class TrackInclude
  attr_reader :includes
  attr_accessor :searchpaths, :heredir

  INCLUDE_REGEX = /^\s*#\s*include\s*(?<mode>[<"])(?<filename>.*?)[">]/

  GLOBAL_SEARCHPATHS = [
    "/usr/include",
    "/usr/local/include",
  ]

  def initialize
    @seen = []
    @includes = []
    @stats = []
    @searchpaths = []
    @heredir = nil
  end

  def find_stat(filename)
    sfp = filename
    # is this file local to to @heredir?
    if @heredir != nil then
      sfp = File.join(@heredir, filename)
    end
    # `blah = somestuff rescue nil` is just short for `blah = begin somestuff; rescue; nil; end`
    # so a failed stat() just returns nil instead of throwing an exception.
    herest = File.stat(sfp) rescue nil
    if herest != nil then
      return herest
    end
    # if not, look at @searchpaths ...
    @searchpaths.each do |dir|
      fp = File.join(dir, filename)
      st = File.stat(fp) rescue nil
      if st != nil then
        return st
      end
    end
    # couldn't find it.
    return nil
  end

  def getlocalpath(filename)
    if @heredir != nil then
      return File.join(@heredir, filename)
    end
    return filename
  end

  def seen_include(ic)
    if @includes.include?(ic) then
      return true
    end
    @includes.each do |needle|
      if (ic.filename != nil) && (ic.filename == needle.filename) then
        return true
      end
    end
    return false
  end

  def check(filename, mode)
    st = find_stat(filename)
    # this is all the dependency checking you get right now.
    # it's fine for what i needed it for.
    if not @seen.include?(st) then
      if st != nil then
        @seen.push(st)
      end
      fpath = filename
      islocal = false
      localpath = getlocalpath(filename)
      if File.file?(localpath) then
        fpath = localpath
        islocal = true
      end
      if st == nil then
        $stderr.printf("-- in check: failed to find %p\n", filename)
      else
        if File.file?(filename) && !filename.scrub.match?(/\.(x|inl)$/i) then
          track_from(filename)
        end
      end
      # this is important: must push **after** checking include!
      # after all, the file being looked at might include something,
      # so that dependency must be resolved first.
      fromheader = fpath.downcase.scrub.match?(/\.(h|hh|hpp|hxx|h\+\+)$/)
      ic = IncludeFile.new(fpath, mode, st, islocal, fromheader)
      if not seen_include(ic) then
        @includes.push(ic)
      end
    end
  end

  def track_from(file)
    $stderr.printf("++ processing %p ...\n", file)
    File.foreach(file) do |line|
      m = line.scrub.match(INCLUDE_REGEX)
      if m then
        incf = m["filename"]
        if !incf.match?(/\.inc$/i) then
          check(incf, m["mode"])
        end
      end
    end
  end
end

class MakeAmalgam
  def initialize(ti)
    @inctracker = ti
    @globalincs = []
    @localincs = []
    @headerincs = []
    ti.includes.each do |itm|
      if itm.isglobal then
        @globalincs.push(itm)
      else
        @localincs.push(itm)
      end
    end
  end

  def write_to_stream(fh)
    @globalincs.each do |itm|
      fh.printf("%s\n", itm.as_cpp)
    end
    fh.printf("\n/* here cometh the local files.... */\n\n")
    @localincs.each do |itm|
      if File.file?(itm.filename) then
        fh.printf("/* file: %p */\n", itm.filename)
        File.open(itm.filename, "rb") do |fi|
          fi.each_line do |line|
            if !line.scrub.match?(TrackInclude::INCLUDE_REGEX) then
              fh.write(line)
            end
          end
        end
        fh.printf("\n")
      else
        fh.printf("#include %p\n", itm.filename)
      end
    end
  end
end

def print_in_order(ti)
  i = 0
  incs = ti.includes
  len = incs.length
  while (i < len) do
    file = incs[i]
    i += 1
    printf("%d:\t%s\n", i-1, file.filename)
  end
end


begin
  opts = OpenStruct.new({
    amalgam: false,
    outputfile: nil,
    searchme: [],
  })
  OptionParser.new{|prs|
    prs.on("-a", "--amalgamate", "create amalgamation header (be warned: this might not work!)"){
      opts.amalgam = true
    }
    prs.on("-o<filename>", "--output=<filename>"){|v|
      opts.outputfile = v
    }
    prs.on("-I<dir>", "add <dir> to paths to search for headers"){|v|
      opts.searchme.push(v)
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("need a start file here. something like 'main.c', or 'main.c'.\n")
    exit(1)
  end
  ti = TrackInclude.new
  ti.searchpaths = opts.searchme
  ARGV.each do |startfile|
    ti.heredir = File.absolute_path(File.dirname(startfile))
    ti.track_from(startfile)
  end
  if !opts.amalgam then
    print_in_order(ti)
  else
    ma = MakeAmalgam.new(ti)
    if opts.outputfile == nil then
      ma.write_to_stream($stdout)
    else
      File.open(opts.outputfile, "wb") do |fh|
        ma.write_to_stream(fh)
      end
    end
  end
end
