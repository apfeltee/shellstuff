#!/usr/bin/ruby

require "ostruct"
require "optparse"

def isdir(path)
  basedir = File.basename(path)
  if File.directory?(path) then
    return true
  end
  if File.symlink?(path) then
    dest = File.realpath(path)
    return File.directory?(dest)
  end
  return false
end

class PathGlob
  def initialize(opts)
    @opts = opts
    @statcache = []
    @paths = ENV["PATH"].split(":").select{|d| isdir(d) }
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

  def cankeep(item)
    #p item
    if (@opts.nonexe == true) then
      return true
    end
    fs = File.stat(item) # rescue nil
    if (fs == nil) then
      return false
    else
      if @statcache.include?(item) then
        return false
      end
    end
    @statcache.push(item)
    if item.match(/\.dll$/i) then
      return false
    end
    if File.executable?(item) then
      return true
    end
    return false
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
            fullp = File.realpath(File.join(path, res))
            if cankeep(fullp) then
              if @opts.fullpaths then
                puts(fullp)
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
