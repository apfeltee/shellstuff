#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optionparser"

def comprx(pat, flags)
  begin
    return Regexp.new(pat, flags)
  rescue => ex
    $stderr.printf("compiling regular expression failed: (%s) %s\n", ex.class.name, ex.message)
    exit(1)
  end
end

def exglob(dir, pat, opts, &b)
  cache = []
  isrx = opts.isregex
  icase = opts.ignorecase
  mustcache = (opts.reversefiles || opts.sortfiles)
  if isrx then
    flags = (icase ? Regexp::IGNORECASE : 0)
    rx = comprx(pat, flags)
    Dir.entries(dir).each do |raw|
      next if ((raw == ".") || (raw == ".."))
      #p [rx, raw, raw.match(rx)]
      if raw.match(rx) != nil then
        if mustcache then
          cache.push(raw)
        else
          b.call(raw)
        end
      end
    end
  else
    flags = (icase ? File::FNM_CASEFOLD : 0)
    Dir.glob(File.join(dir, pat), flags) do |path|
      name = File.basename(path)
      next if ((name == ".") || (name == ".."))
      if mustcache then
        cache.push(name)
      else
        b.call(name)
      end
    end
  end
  if mustcache then
    if opts.sortfiles then
      cache = cache.sort
    end
    if opts.reversefiles then
      cache = cache.reverse
    end
    cache.each{|s| b.call(s) }
  end
end

class DoGlob
  def initialize(prog, dir, pat)
    @prog = prog
    @dir = dir
    @pat = pat
    @opts = @prog.opts
  end

  def format(fname, abspath)
    if File.directory?(abspath) then
      return (fname + "/")
    end
    return fname
  end

  def main
    #Dir.glob(@pat) do |raw|
    exglob(@dir, @pat, @opts) do |raw|
      realp = File.absolute_path(raw)
      item = format(raw, realp)
      @prog.output(item, realp)
    end
  end
end

class GlobProgram
  attr_accessor :opts

  def initialize(opts)
    @opts = opts
  end

  def output(name, realp)
    $stdout.puts(name)
  end

  def main(pat, dirs)
    dirs.each do |d|
      DoGlob.new(self, d, pat).main
    end
  end
end

begin
  opts = OpenStruct.new({
    isregex: false,
    ignorecase: false,
    reversefiles: false,
    sortfiles: true,
  })
  (prs=OptionParser.new{|prs|
    prs.on("-x", "--regex", "interpret pattern as a regular expression"){|_|
      opts.isregex = true
    }
    prs.on("-c", "-i", "--icase", "case insensitive matching"){|_|
      opts.ignorecase = true
    }
    prs.on("-r", "--reverse", "reverse output"){|_|
      opts.reversefiles = true
    }
    prs.on("-s", "--sort", "sort files"){|_|
      opts.sortfiles = true
    }
  }).parse!
  pat = ARGV.shift
  dirs = ARGV
  if pat.nil? then
    $stderr.puts("missing pattern")
    $stderr.puts(prs.help)
    exit(1)
  else
    if dirs.empty? then
      dirs.push(".")
    end
    GlobProgram.new(opts).main(pat, dirs)
  end
end


