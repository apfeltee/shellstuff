#!/usr/bin/ruby --disable-gems

require "optionparser"

def myipv4
  system(*%w{dig +short myip.opendns.com @resolver1.opendns.com})
end

def myipv6
  system(*%w{dig +short -6 myip.opendns.com aaaa @resolver1.ipv6-sandbox.opendns.com})
end

begin
  want = :ipv4
  wantboth = true
  OptionParser.new{|r|
    r.on("-4", "--ipv4", "return ipv4 address"){|_|
      wantboth = false
      want = :ipv4
    }
    r.on("-6", "--ipv6", "return ipv6 address"){|_|
      wantboth = false
      want = :ipv6
    }
  }.parse!
  if wantboth then
    myipv4
    myipv6
  else
    myipv4 if want == :ipv4
    myipv6 if want == :ipv6
  end
end