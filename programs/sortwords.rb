#!/usr/bin/ruby

require "ostruct"
require "optparse"


def warn(msg, *args)
  str = (if args.empty? then msg else sprintf(msg, *args) end)
  $stderr.printf("warning: %s\n", str)
end

def error(msg, *args)
  str = (if args.empty? then msg else sprintf(msg, *args) end)
  $stderr.printf("error: %s\n", str)
  exit(1)
end

class SortWords
  def initialize(sepstr, idx, opts)
    @names = Hash.new{|selfh, key| selfh[key]=0; }
    @sepstr = sepstr
    @seprx = Regexp.new(Regexp.quote(@sepstr))
    @index = idx
    @opts = opts
  end

  def push(string)
    #$stdin.each_line do |l|
      #w = l.strip.split(/-/)[0]; h[w] += 1; }; h.sort_by{|k, v| v}.each do |k, v|
        #printf("%d\t%s\n", v, k)
      #end
    #end
    if string.include?(@sepstr) then
      itms = string.split(@seprx)
      val = itms[@index]
      if val == nil then
        warn("index %d for %p out of bounds", @index, itms)
      else
        val = if @opts.ignorecase then val.downcase else val end
        @names[val] += 1
      end
    else
      warn("separator %p not found in %p", @sepstr, string)
    end
  end

  def each(&b)
    sorted = @names.sort_by{|k, v| v}
    if @opts.reverse then
      sorted = sorted.reverse
    end
    sorted.each(&b)
  end
end

def get_input(&b)
  if ARGV.empty? then
    if $stdin.tty? then
      error("no arguments given, and nothing piped!")
    else
      $stdin.each_line do |line|
        line.scrub!
        line.strip!
        b.call(line)
      end
    end
  else
    ARGV.each(&b)
  end
end

begin
  index = 0
  sepstr = nil
  opts = OpenStruct.new({
    ignorecase: false,
    reverse: false,
  })
  
  OptionParser.new{|prs|
    prs.on("-s<str>", "--separator=<s>", "specify separator"){|s|
      sepstr = s
    }
    prs.on("-i<n>", "--index=<n>", "specify index (default: 0)"){|s|
      index = s.to_i
    }
    
  }.parse!
  if (sepstr == nil) && (not ARGV.empty?)
    sepstr = ARGV.shift
  end
  error("separator not specified via -s; cannot continue") if sepstr.nil?
  error("index not specified via -i, or negative; cannot continue") if (index.nil? || (index < 0))
  sw = SortWords.new(sepstr, index, opts)
  get_input do |arg|
    sw.push(arg)
  end
  sw.each do |name, sz|
    $stdout.printf("%-10d %s\n", sz, name)
    $stdout.flush
  end
end
