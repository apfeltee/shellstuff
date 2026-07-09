#!/usr/bin/ruby

=begin
# converts numeric byte sizes to human readable sizes.
# i.e.,
#
#   $ stoh '275,348,143,364'
#   275348143364 -> 256.4G
#
=end
require "ostruct"
require "optparse"

module Util
  def self.size_to_readable(size)
    {
      'B'  => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair{|e, s|
      if size < s then
        return "#{(size.to_f / (s / 1024)).round(2)}#{e}"
      end
    }

    # byte, kilobyte, megabyte, gigabyte, terabyte, petabyte, exabyte, zettabyte
    # the last two seem... unlikely, tbh
    units = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']
    if (size == 0) then
      return '0B'
    end
    exp = (Math.log(size) / Math.log(1024)).to_i
    if (exp > 6) then
      exp = 6
    end
    return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
  end
end

class SizeToHuman
  def initialize(opts)
    @opts = opts
  end

  def runNumber(num)
    
    printf("%s -> %s\n", num, Util.size_to_readable(num))
  end

  def runDelim(str, delim)
    runNumber(str.split(delim).map(&:strip).reject(&:empty?).join.to_i)
  end

  def run(str)
    str.scrub!
    if str.match?(/^\d+$/) then
      runNumber(str.to_i)
    elsif str.match(/^\d+\.\d+/) then
      runDelim(str, '.')
    elsif str.match(/^\d+,\d+/) then
      runDelim(str, ',')
    else
      begin
        val = eval(str)
      rescue => err
        $stderr.printf("don't know how to parse %p - eval failed: (%s) %s\n", str, ex.class.name, ex.message)
      end
    end
  end
end

begin
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
  
  }.parse!
  stoh = SizeToHuman.new(opts)
  if not $stdin.tty? then
    stoh.run($stdin.read)
  else
    ARGV.each do |arg|
      stoh.run(arg)
    end
  end
end

