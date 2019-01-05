#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"

def strtonum(str)
  sum = ""
  str.each_byte{|b| sum += b.to_s }
  return sum
end

def to_hex(str, opts)
  num = str.send(opts.recv)
  fmt = ""
  fmt += "0x" if opts.nullx
  fmt += "%"
  if opts.nullpads > 0 then
    fmt += "0#{opts.nullpads}"
  end
  fmt += "X"
  return sprintf(fmt, num)
end

def handle(arg, opts)
  inp = arg.dup
  if opts.fromstring then
    inp = strtonum(arg)
  end
  $stdout.printf("%s", to_hex(inp, opts))

  if opts.columnize.nil? then
    if opts.nonewline then
      $stdout.write(' ')
    else
      $stdout.puts
    end
  else
    if opts.colcount == opts.columnize then
      $stdout.puts
      opts.colcount = 0
    else
      $stdout.write(' ')
      opts.colcount += 1
    end
  end
end



begin
  opts = OpenStruct.new({
    recv: "to_i",
    nullpads: 2,
    nullx: false,
    fromstring: false,
    nonewline: false,
    columnize: nil,
    colcount: 0
  })
  $stdout.sync = true
  OptionParser.new{|prs|
    prs.on("-f", "if specified, assume input to be a floating point number"){
      opts.recv = "to_f"
    }
    prs.on("-0<n>", "set amount ot 0s to pad to"){|v|
      opts.nullpads = v.to_i
    }
    prs.on("-x", "if specified, output with '0x' prefix"){
      opts.nullx = true
    }
    prs.on("-s", "assume input are strings (numeric or not), thus input = sum of bytes"){
      opts.fromstring = true
    }
    prs.on("-n", "do not add newlines"){
      opts.nonewline = true
    }
    prs.on("-c<n>", "columnize with <n> sized rows"){|v|
      opts.columnize = v.to_i
    }
  }.parse!
  begin
    if ARGV.empty? then
      if $stdin.tty? then
        $stderr.printf("error: no arguments given, and nothing piped\n")
        exit(1)
      else
        $stdin.each_line do |line|
          line.strip!
          handle(line, opts)
        end
      end
    else
      ARGV.each do |arg|
        handle(arg, opts)
      end
    end
  ensure
    if opts.nonewline || ((opts.columnize != nil) && (opts.colcount != 0)) then
      $stdout.puts
    end
  end
end
