#!/usr/bin/ruby --disable-gems

require "optparse"

def getargs
  if ARGV.empty? then
    if not $stdin.tty? then
      return $stdin.each_line.to_a.map(&:strip).reject(&:empty?)
    else
      $stderr.printf("no arguments given, and nothing piped\n")
      exit(1)
    end
  else
    return ARGV
  end
end

def canprint(path, wanttype)
  return (
    ((wanttype == "f") && File.file?(path)) ||
    ((wanttype == "d") && File.directory?(path))
  )
end

def main(args, wanttype)
  rcode = 0
  args.each do |arg|
    if canprint(arg, wanttype) then
      $stdout.puts(arg)
      $stdout.flush
    else
      rcode = 1
    end
  end
  return rcode
end

begin
  wanttype = nil
  OptionParser.new{|prs|
    prs.on("-t<c>", "--type=<c>"){|v|
      wanttype = v.strip[0]
    }
    prs.on("-f", "--file"){|_|
      wanttype = "f"
    }
    prs.on("-d", "--dir"){|_|
      wanttype = "d"
    }
  }.parse!
  if wanttype.nil? then
    $stderr.printf("error: you must specify a type\n")
    exit(1)
  else
    args = getargs
    exit(main(args, wanttype))
  end
end

