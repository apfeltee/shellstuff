#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "securerandom"

# the eicar test string, +1'd for obvious reasons
VTESTSTR = "FJDBS.TUBOEBSE.BOUJWJSVT.UFTU.GJMF".bytes.map(&:pred).map(&:chr).join

BADCHARS = %w(i I l L q g z Z s S 0 1 2 3 4 5 6 7 8 9)
DEFAULTLENGTH = 10
DEFAULTAMOUNT = 1
DEFAULTBUFSIZE = 50

module CType
  def self.isprint(b)
    return ((b >= 040) && (b < 0177))
  end

  def self.isdigit(b)
    return ((b <= '9'.ord) && (b >= '0'.ord))
  end

  def self.isspace(b)
    return ((b == 32) || (b == 9) || (b == 13) || (b == 10) || (b == 12))
  end

  def self.isascii(b)
    return ((b < 0200) && (b >= 0))
  end

  def self.isupper(c)
    return ((c <= 'Z'.ord) && (c >= 'A'.ord))
  end

  def self.islower(c)
    return ((c <= 'z'.ord) && ( c >= 'a'.ord))
  end

  def self.isalpha(c)
    return (isupper(c) || islower(c))
  end

  def self.isalnum(c)
    return (isalpha(c) || isdigit(c))
  end


  #define iscntrl(c) (((c) < 040 || (c) == 0177) && isascii((c)))
  #define ispunct(c) (!isalnum((c)) && isprint(c))
  #define toupper(c) (islower((c)) ? (c) & ~32 : (c))
  #define tolower(c) (isupper((c)) ? (c) | 32 : (c))
  #define toascii(c) ((c) & 0177)

end

class MkRand
  def initialize(opts)
    @opts = opts
  end

  # unless --all is specified, filter out ambigiuous characters also
  def isbadchar(bch)
    if (@opts.useall == false) then
      if @opts.usesymbols == false then
        if not CType.isalnum(bch) then
          return true
        end
      end
      if (@opts.lconly == true) then
        if !CType.islower(bch) then
          return true
        end
      end
      if BADCHARS.include?(bch) then
        return true
      end
    end
    return false
  end

  # return true if the byte is a usable one.
  def canpush(bch)
    if CType.isprint(bch) && !CType.isspace(bch) then
      if not isbadchar(bch) then
        return true
      end
    end
    return false
  end

  # read bytes, and filter out any non-ascii and non-printable bits.
  def getrandchars()
    got = []
    needed = @opts.bufsz
    while got.length < needed do
      tmp = SecureRandom.bytes(@opts.bufsz)
      tmp.each_byte do |bch|
        chr = bch.chr
        if canpush(bch) then
          got.push(chr)
        end
      end
    end
    return got
  end

  def gennormal()
    rtbuf = []
    rtsz = 0
    updcnt = 0
    randbuf = getrandchars()
    randlen = randbuf.size
    randidx = 0
    # loop until requested @opts.minlen is achieved
    while true do
      if (rtsz == @opts.minlen) then
        break
      else
        # update $randbuf if we've reached the end of it
        if (randidx == randlen) then
          randbuf = getrandchars()
          randlen = randbuf.size
          randidx = 0
          updcnt += 1
        end
        ch = randbuf[randidx]
        rtbuf.push(ch)
        rtsz += 1
        randidx += 1
      end
    end
    rtstr = rtbuf.join
    return rtstr
  end

  def geneicar()
    sbefore = gennormal()
    safter = gennormal()
    return [sbefore, VTESTSTR, safter].join
  end

  def randpass
    if @opts.eicar then
      return geneicar()
    end
    return gennormal()
  end
end

begin
  opts = OpenStruct.new({
    minlen: DEFAULTLENGTH,
    thismany: DEFAULTAMOUNT,
    bufsz: DEFAULTBUFSIZE,
    eicar: false,
    useall: false,
    usesymbols: false,
    lconly: false,
  })
  $stdout.sync = true
  OptionParser.new{|prs|
    prs.on("-l<n>", "--length=<n>", "specify length of requested password (default: #{DEFAULTLENGTH})"){|v|
      opts.minlen = v.to_i
    }
    prs.on("-n<n>", "--times=<n>", "how many passwords you want (default: 1)"){|v|
      opts.thismany = v.to_i
    }
    prs.on("-b<n>", "--buffersize=<n>"){|v|
      opts.bufsz = v.to_i
    }
    prs.on("-a", "--all", "allow all (even ambigious!) characters"){
      opts.useall = true
    }
    prs.on("-c", "--lowercase", "only allow lowercase characters"){
      opts.lconly = true
    }
    prs.on("-s", "--symbols", "include symbols ('(', '&', '*', et cetera)"){
      opts.usesymbols = true
    }
    prs.on("-e", "--eicar", "generate a random string that incorporates the EICAR test string"){
      opts.eicar = true
    }
  }.parse!
  mkr = MkRand.new(opts)
  i = 0
  while i < opts.thismany do
    i += 1
    puts(mkr.randpass())
  end
end

