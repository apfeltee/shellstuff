#!/usr/bin/ruby

require "ostruct"
require "optparse"

class MoveExt
  def initialize(opts)
    @opts = opts
  end
end

begin
  opts = OpenStruct.new({
  })
  OptionParser.new{
  }.parse!
  pat = ARGV.shift
  if pat == nil || ARGV.empty? then
    $stderr.printf("expect")
end




