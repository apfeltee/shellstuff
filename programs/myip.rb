#!/usr/bin/ruby --disable-gems

require "optionparser"

def syswrap(cmd)
  #$stderr.printf("cmd=%p\n", cmd)
  IO.popen(cmd, "rb"){|io|
    return io.read
  }
end

def sys(cmd)
  rv = syswrap(cmd)
  rv.strip!
  if rv[0] == '"' && rv[rv.length - 1] == '"' then
    return rv[1 .. rv.length-2]
  end
  return rv
end

def getmyip(useipv4)
  #dig +short myip.opendns.com @resolver1.opendns.com
  #sys(*%w{dig +short -4 myip.opendns.com @resolver1.opendns.com})
  extra = []
  if !useipv4 then
    extra.push("-6")
  else
    extra.push("-4")
  end
  #sys(["dig", "+short", *extra, "myip.opendns.com", "@resolver1.opendns.com"])
  rv = sys(["dig", *extra, "ANY", "+short", "o-o.myaddr.l.google.com", "@ns1.google.com"])
  $stdout.printf("%s\n", rv)
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
    getmyip(true)
    getmyip(false)
  else
    getmyip(true) if want == :ipv4
    getmyip(false) if want == :ipv6
  end
end