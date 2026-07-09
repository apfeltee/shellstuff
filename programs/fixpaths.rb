#!/usr/bin/ruby

require "find"
require "optparse"

class FixPaths
  attr_reader :errors

  def initialize()
    @errors = 0
  end

  def complain(*args)
    $stderr.printf("ERROR: ")
    $stderr.printf(*args)
    $stderr.printf("\n")
    @errors += 1
  end

  def rename(from, to)
    begin
      return File.rename(from, to)
    rescue => ex
      complain("exception raised: (%s) %s", ex.class.name, ex.message)
    end
    return false
  end

  def todowncase(path)
    dirn = File.dirname(path)
    basen = File.basename(path)
    dbase = basen.downcase
    if dbase != basen then
      npath = File.join(dirn, dbase)
      temppath = npath + "._fixpath_temp"
      if rename(path, temppath) then
        if rename(temppath, npath) then
          $stderr.printf("in %p: %p -> %p\n", dirn, basen, dbase)
        else
          complain("failed to rename %p to %p", temppath, npath)
        end
      else
        complain("failed to rename %p to %p", path, temppath)
      end
      return npath
    end
    return path
  end

  def recursein(dir)
    if File.directory?(dir) then
      todo = []
      Find.find(dir) do |item|
        newname = todowncase(item)
        #if File.directory?(newname) then
          #todo.push(newname)
        #end
      end
    else
    end
  end

  def handleitem(item)
    if File.file?(item) then
      todowncase(item)
    elsif File.directory?(item)
      recursein(item)
    else
      complain("not a file or directory: %p", item)    
    end
  end
end

begin
  OptionParser.new{|prs|
  }.parse!
  fp = FixPaths.new
  ARGV.each do |item|
    fp.handleitem(item)
  end
  rc = ((fp.errors == 0) ? 0 : 1)
end
