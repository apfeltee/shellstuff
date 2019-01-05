#!/usr/bin/ruby

class PathGlob
  def initialize
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

  def glob(str)
    @paths.each do |path|
      if File.directory?(path) then
        Dir.glob(path + "/" + str, File::FNM_CASEFOLD) do |res|
          next if res.match(/\.dll$/i)
          if File.executable?(res) || true then
            puts(res)
            checkdupes(res)
          end
        end
      end
    end
  end
end

begin
  pats = ARGV
  pg = PathGlob.new
  if pats.empty? then
    pats = ["*"]
  end
  pats.each do |pat|
    pg.glob(pat)
  end
end
