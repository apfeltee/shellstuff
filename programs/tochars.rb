#!/usr/bin/ruby

class Bin2C
  MAX_COLS = 4

  def fix(ch)
    return "0x%02X" % ch
  end

  def readinput
    if ARGV.length > 0 then
      return File.open(ARGV[0], "rb").read
    else
      return $stdin.read
    end
  end

  def getoutput
    if ARGV.length > 1 then
      return File.open(ARGV[1], "w")
    else
      return $stdout
    end
  end

  def initialize
    input = readinput
    output = getoutput
    size_count = 0
    line_count = 0
    input.each_byte do |ch|
      endline = (line_count == (MAX_COLS - 1))
      output.printf("%s", fix(ch))
      if (size_count+1) < input.length then
        output.print(",")
      end
      if endline then
        output.puts
        line_count = 0
      else
        output.print(" ")
        line_count += 1
      end
      size_count += 1
    end
  end
end

Bin2C.new
