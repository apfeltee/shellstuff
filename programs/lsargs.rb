#!/usr/bin/ruby

begin
  $stdout.sync = true
  ARGV.each_with_index do |arg, i|
    printf("argv[%03d] = %p\n", i, arg)
  end
end
