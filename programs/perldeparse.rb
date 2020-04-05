#!/usr/bin/ruby

# i really, REALLY do not like perl. but it also feels wrong to do this in ruby.
#
require "optparse"

# check 'perldoc B::Deparse' for other flags and what they do
# these options are for B::Deparse(), that is, they get forwarded
DEFOPTIONS = [
  ["-q", ["-q", "--qstrings"], "expands double-quoted strings"],
  ["-d", ["-d", "--dump"], "dumps data values when they're used as constants (such as strings)"],
  ["-p", ["-p", "--parens"], "adds additional parentheses"],
  ["-P", ["-n", "--noproto"], "disables prototype checking"],
]

def deparse(opts, fh)
  sflags = opts.join(",")
  scmd = ["perl", "-MO=Deparse,#{sflags}"]
  if fh.is_a?(IO) then
    IO.popen(scmd, "wb") do |io|
      io.write(fh.read)
      io.close
    end
  else
    system([*scmd, fh])
  end
end

begin
  opts = []
  indlevel = 4
  syncon = 0
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-x<n>", "--expand=<n>", "expand syntax constructions where n can be 0..9"){|v|
      syncon = v.to_i
    }
    prs.on("-i<n>", "--indent=<n>", "indent with <n> spaces"){|v|
      indlevel = v.to_i
    }
    DEFOPTIONS.each do |inf|
      realopt = inf.shift
      ops = inf.shift
      desc = inf.shift
      prs.on(*ops, desc){
        opts.push(realopt)
      }
    end
  }.parse!
  opts.push(sprintf("-x%d", syncon))
  opts.push(sprintf("-si%d", indlevel))
  if ARGV.empty? then
    deparse(opts, $stdin)
  else
    ARGV.each do |arg|
      File.open(arg, "rb") do |fh|
        deparse(opts, fh)
      end
    end
  end
end


