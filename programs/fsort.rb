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

class BaseSort
  def initialize(opts)
    @opts = opts
  end
end

class SortBySize
  def where
    
  end
end

SORTMETHODS = {
  "size" => SortBySize,
}

def get_method(name)
  if not SORTMETHODS.key?(name) then
    error("no sorting method named %p", name)
  end
  return SORTMETHODS[name]
end

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

