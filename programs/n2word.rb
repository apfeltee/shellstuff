#!/usr/bin/ruby

require 'linguistics'
Linguistics.use(:en)

def n2word(val)
  words = val.en.numwords
  puts("#{val}: #{words}")
end

if ARGV.length == 0 then
  # the '=' is not a typo
  while line = $stdin.gets
    n2word(line.strip.to_i)
  end
else
  ARGV.each do |val|
    n2word(val.to_i)
  end
end
