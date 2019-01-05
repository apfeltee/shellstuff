#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"

def skip_io(fh, opts)
  #$stderr.printf("fh=%p, opts=%p\n", fh, opts)
  idx = 0
  iline = 1
  maywrite = false
  # cache opts, because OpenStruct access is surprisingly slow ...
  obegin = opts.ibegin
  oend = opts.iend
  out = opts.outhandle
  out.sync = true
  while true do
    begin
      # IO#readline raises EOFError - this isn't a system error per se,
      # but MUST be handled anyway!
      strline = fh.readline
      #$stderr.printf("idx=%p, strline=%p\n", idx, strline)
      if (idx == obegin) then
        maywrite = true
      elsif ((oend != 0) && (idx == oend)) then
        maywrite = false
        # important: once oend is reached, there's no point in continuing to read
        return 0
      else
        if (maywrite == true) then
          out.write(strline)
          out.flush
        end
      end
      idx += 1
      iline += 1
    rescue EOFError
      return 0
    end
  end
  return 0
end

def skip_file(fpath, opts)
  begin
    File.open(fpath, "rb") do |fh|
      return skip_io(fh, opts)
    end
  rescue Interrupt
    # nothing
    return 0
  rescue => ex
    $stderr.printf("skip_file: (%s) %s\n", ex.class.name, ex.message)
    return 1
  end
end

begin
  opts = OpenStruct.new({
    ibegin: 0,
    iend: 0,
    outhandle: $stdout,
  })
  custoutput = false
  rtcode = 0
  OptionParser.new{|prs|
    prs.on("-b<n>", "--begin=<n>", "start at line <n>"){|v|
      opts.ibegin = v.to_i
    }
    prs.on("-e<n>", "--end=<n>", "read until line <n>"){|v|
      opts.iend = v.to_i
    }
    prs.on("-o<path>", "--output=<path>", "write output to <path> instead of stdout"){|v|
      custoutput = true
      opts.outhandle = File.open(v, "wb")
    }
  }.parse!
  begin
    if ARGV.empty? then
      if $stdin.tty? then
        $stderr.printf("error: no files given, and nothing piped\n")
        exit(1)
      else
        rtcode += skip_io($stdin, opts)
      end
    else
      ARGV.each do |arg|
        rtcode += skip_file(arg, opts)
      end
    end
  ensure
    if custoutput then
      opts.outhandle.close
    end
  end
  exit(rtcode)
end

