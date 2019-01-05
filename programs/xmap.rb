#!/usr/bin/ruby

require "optparse"

def shmap(args, line, donot)
  ret = system(*args, line)
  if ret then
    if donot == false then
      $stdout.puts(line)
    end
  end
end

begin
  donot = false
  OptionParser.new{|prs|
    prs.on("-!", "--not"){|_|
      donot = true
    }
  }.parse!
  $stdin.each_line do |line|
    shmap(ARGV, line.gsub(/[\r\n]$/, ""), donot)
  end
end

