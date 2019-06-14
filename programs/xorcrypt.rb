#!/usr/bin/ruby

=begin
  fun fact:

    xorcrypt -k0 < somefile.blah | xorcrypt -k1 | xorcrypt -k2 | xorcrypt -k3 | xorcrypt -k4 | xorcrypt -k5 | xorcrypt -k012345

  will accurately "encrypt" / "decrypt" somefile.blah!
  that is, a chain of "0", "1", "2", "3", "4", "5" equals "012345".
  not exactly useful, but maybe interesting.

=end

require "ostruct"
require "optparse"

def xorcrypt(inio, outio, opts)
  keystr = opts.key
  keybytes = keystr.bytes
  inio.each_byte do |inb|
    tmp = inb
    keybytes.each do |keyb|
      tmp = (tmp ^ keyb)
    end
    outio.putc(tmp)
  end
end

def get_input(opts, &b)
  errorcnt = 0
  if ARGV.empty? then
    if $stdin.tty? then
      # useless use of cat, BUT writing "xorcrypt -p<s> < <file>" would
      # just look confusing, so stfu
      $stderr.printf(
        "usage:\n" +
        "   xorcrypt -k<phrase> <file...>\n" +
        "   cat <file> | xorcrypt -k<phrase>\n"
      )
      exit(1)
    else
      b.call($stdin)
    end
  else
    if (opts.ofile != nil) && (ARGV.length > 1) then
      $stderr.printf("xorcrypt: '-o' can only be used with one file argument\n")
      exit(1)
    end
    ARGV.each do |arg|
      if File.file?(arg) then
        File.open(arg, "rb", &b)
      else
        $stderr.printf("xorcrypt: not a file: %p\n", arg)
        errorcnt += 1
      end
    end
    exit((errorcnt > 0) ? 1 : 0)
  end
end

def interp_binary(str)
  buf = []
  str.split(",").map(&:strip).reject(&:empty?).each do |v|
    buf.push(v.to_i.chr)
  end
  j = buf.join
  $stderr.printf("interp_binary: buf=%p j=%p\n", buf, j)
  return j
end

begin
  opts = OpenStruct.new({
    key: nil,
    do_encrypt: true,
    ohnd: $stdout,
    ofile: nil,
    interpbinary: false,
  })
  OptionParser.new{|prs|
    prs.on("-k<str>", "--key=<str>", "specify <str> as key"){|v|
      opts.key = v
    }
    prs.on("-f<file>", "--keyfile=<file>", "use contents of <file> as key"){|v|
      if File.file?(v) then
        # lazy
        opts.key = File.read(v)
      else
        $stderr.printf("xorcrypt: error: specified keyfile %p is not a file\n", v)
        exit(1)
      end
    }
    prs.on("-b", "--binary", "interpret key to be comma-separated binary bytes"){|_|
      opts.interpbinary = true
    }
    prs.on("-o<file>", "--output=<file>", "write output to <file>"){|v|
      tmpfh = File.open(v, "wb")
      opts.ofile = v
      opts.ohnd = tmpfh
    }
  }.parse!
  begin
    if opts.interpbinary then
      opts.key = interp_binary(opts.key)
    end
    get_input(opts) do |fh|
      if opts.key == nil then
        $stderr.printf("xorcrypt: you must specify a key via '-k<string>' or '-f<file>'\n")
        exit(1)
      end
      xorcrypt(fh, opts.ohnd, opts)
    end
  ensure
    if opts.ofile != nil then
      opts.ohnd.close
    end
  end
end

