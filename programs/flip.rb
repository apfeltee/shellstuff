#!/usr/bin/ruby

require "optparse"

def can_flip(b, n)
  return (((b + n) > 32) && ((b + n) < 127))
end

def flip(thing, n, &blawk)
  thing.each_byte do |b|
    ob = b
    if can_flip(b, n) then
      ob = (b+n)
    end
    blawk.call(ob)
  end
end

begin
  amount = 1
  OptionParser.new{|prs|
    prs.on("-<d>", "-n<d>", "--amount=<d>"){|v|
      amount = v.to_i
    }
  }.parse!
  flip($stdin, amount) do |b|
    $stdout.putc(b)
    $stdout.flush
  end
end







