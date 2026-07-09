#!/usr/bin/ruby

require "ostruct"
require "optparse"

class Longest
  def initialize(opts)
    @opts = opts
    @buffer = []
    @currlongestcount = 0
    @currlongestline = nil
  end

  def read_handle(hnd)
    hnd.each_line do |line|
      line = line.rstrip
      len = line.length
      if len > @currlongestcount then
        @currlongestcount = len
        @currlongestline = line
      end
      @buffer.push(line)
    end
  end

  def read_stdin(&b)
    read_handle($stdin)
  end

  def print_results
    sorted = nil
    if @opts.nosort then
      sorted = @buffer
    else
      sorted = @buffer.sort_by{|s| s.length}
    end
    sorted.each do |line|
      printf("%d\t%s\n", line.length, line)
    end
  end

end

begin
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
  
  }.parse!
  cx = Longest.new(opts)
  if ARGV.empty? then
    cx.read_stdin
  else
    ARGV.each do |f|
      File.open(f, "rb") do |fh|
        cx.read_handle(fh)
      end
    end
  end
  cx.print_results
end
