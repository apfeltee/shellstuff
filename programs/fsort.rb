#!/usr/bin/ruby --disable-gems

require "optparse"
require "ostruct"

def iofmt(io, pre, fmt, *args)
  io.printf("%s: %s\n", (if args.empty? then fmt else sprintf(fmt, *args) end))
end

def verbose(fmt, *args)
  iofmt($stderr, "verbose", fmt, *args)
end

def error(fmt, *args)
  iofmt($stderr, "error", fmt, *args)
  exit(1)
end

=begin
fext: .swf
player: c:/cloud/gdrive/portable/flashplayer.exe


=end


begin
  opts = OpenStruct.new({
    sortmethod: get_method("size"),
    inputstdin: false,
  })
  OptionParser.new{|prs|
    prs.on("-m<m>", "--method=<m>", "sort using method <m>"){|v|
      opts.sortmethod = get_method(v)
    }
    prs.on("-i", "--stdin", "read input from stdin"){|_|
      opts.inputstdin = true
    }
  }.parse!
  main(opts, ARGV)
end

