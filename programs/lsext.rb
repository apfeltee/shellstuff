#!/usr/bin/ruby

require 'pp'

class ListByExtension
  def initialize(path)
    @allfiles = {}
    @path = path
    raise "not a path" unless File.directory?(path)
    getFiles
    printFiles($stdout)
  end

  def getFiles
    Dir.entries(@path).each do |file|
      filepath = File.join(@path, file)
      if File.file?(filepath) then
        ext = File.extname(filepath)
        if @allfiles[ext] == nil then
          @allfiles[ext] = []
        end
        @allfiles[ext] << filepath
      end
    end
  end

  def printFiles(to)
    @allfiles.each do |ext, flist|
      to.printf("%s: \n", ext)
      to.flush
      flist.each do |filepath|
      to.printf("   %s\n", filepath)
      to.flush
      end
    end
  end
end

ListByExtension.new(ARGV[0] || ".")
