#!/usr/bin/ruby --disable-gems

require "securerandom"
require "optparse"


BADCHARS = %w(i I l L o O 0 q g 9 z Z s S 1)
DEFAULTLENGTH = 10
DEFAULTAMOUNT = 1
DEFAULTBUFSIZE = 50

def getrandchars(bufsz)
  rt = SecureRandom.hex(bufsz)
  return rt
end

def randpass(len, bufsz)
  rtbuf = []
  rtsz = 0
  updcnt = 0
  randbuf = getrandchars(bufsz)
  randlen = randbuf.size
  randidx = 0
  # loop until requested $len is achieved
  while true do
    if (rtsz == len) then
      break
    else
      # update $randbuf if we've reached the end of it
      if (randidx == randlen) then
        randbuf = getrandchars(bufsz)
        randlen = randbuf.size
        randidx = 0
        updcnt += 1
      end
      ch = randbuf[randidx]
      # only push chars that are not in BADCHARS ... to avoid ambigious chars!
      if not BADCHARS.include?(ch) then
        rtbuf.push(ch)
        rtsz += 1
      end
      randidx += 1
    end
  end
  rtstr = rtbuf.join
  $stderr.printf("-- did %d updates\n", updcnt)
  # all done
  return rtstr
end

begin
  length = DEFAULTLENGTH
  thismany = DEFAULTAMOUNT
  bufsz = DEFAULTBUFSIZE
  $stdout.sync = true
  OptionParser.new{|prs|
    prs.on("-l<n>", "--length=<n>", "specify length of requested password (default: #{DEFAULTLENGTH})"){|v|
      length = v.to_i
    }
    prs.on("-n<n>", "--times=<n>", "how many passwords you want (default: 1)"){|v|
      thismany = v.to_i
    }
    prs.on("-b<n>", "--buffersize=<n>"){|v|
      bufsz = v.to_i
    }
  }.parse!
  thismany.times{
    puts(randpass(length, bufsz))
  }
end

