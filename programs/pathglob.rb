#!/usr/bin/ruby

require "ostruct"
require "optparse"

class PathGlob
  def initialize(opts)
    @opts = opts
    @statcache = []
    @paths = ENV["PATH"].split(":").select{|d| File.directory?(d) }
    @dupes = Hash.new{|hash, key| hash[key] = [] }
  end

  def checkdupes(res)
    base = File.basename(res).downcase
    if @dupes[base].length > 1 then
      $stderr.printf("warning: duplicate executables found:\n")
      @dupes[base].each do |item|
        $stderr.printf("  %p\n", item)
      end
    else
      @dupes[base].push(res)
    end
  end

  def canskip(item)
    if (@opts.nonexe == true) then
      return false
    end
    fs = File.stat(item) rescue nil
    if (fs != nil) && @statcache.include?(fs) then
      return true
    end
    @statcache.push(fs)
    return true if item.match(/\.dll$/i)
    if File.executable?(item) then
      return false
    end
  end

  def try_chdir(d, &b)
    begin
      Dir.chdir(d, &b)
    rescue => ex
      $stderr.printf("pathglob: error: chdir(%p): (%s) %s\n", d, ex.class.name, ex.message)
    end
  end

  def glob(str)
    @paths.each do |path|
      if File.directory?(path) then
        try_chdir(path) do
          Dir.glob(str, File::FNM_CASEFOLD) do |res|
            #p res
            next if canskip(res)
            if @opts.fullpaths then
              puts(File.join(path, res))
            else
              puts(res)
            end
            checkdupes(res)
          end
        end
      end
    end
  end
end

begin
  opts = OpenStruct.new({
    autoglob: false,
    nonexe: false,
    fullpaths: false,
  })
  OptionParser.new{|prs|
    prs.on("-g", "--autoglob", "automatically wraps each term in wildcards"){
      opts.autoglob = true
    }
    prs.on("-p", "-f", "--fullpath", "print the full paths, instead of just the name"){
      opts.fullpaths = true
    }
    prs.on("-x", "--no-exe", "also print non-executable files"){|_|
      opts.nonexe = true
    }
  }.parse!
  pats = ARGV
  pg = PathGlob.new(opts)
  if pats.empty? then
    pats = ["*"]
  else
    if opts.autoglob then
      pats.map!{|pv| ("*" + pv + "*") }
    end
  end
  pats.each do |pat|
    pg.glob(pat)
  end
end
