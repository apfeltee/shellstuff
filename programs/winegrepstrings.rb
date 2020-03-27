#!/usr/bin/ruby

#
# constructs patterns to search for wine-like strings, such as:
#
#   static const WCHAR poop[] = {'w','i','n','e','h','q', 0};
#
# don't ask me WHY wine specifies strings this way. that's just how it is, i guess.
# maybe they're masochistic? who knows.
#

require "optparse"

def mkpattern(instr)
  buf = []
  instr.each_char do |ch|
    dumped = (
      if ch == "'" then
        '\\\''
      else
        #ch.dump[1 .. -2]
        Regexp.quote(ch)
      end
    )
    # include wide character specifier - if it exists
    buf.push("L?'" + dumped + "'")
  end
  # this isn't going to work with linefeeds!
  return buf.join('\s*,\s*')
end

begin
  recursive = false
  cmd = cmd = ["grep", "--color=auto", "-P"]
  OptionParser.new{|prs|
    prs.on("-i", "ignore case distinctions"){
      cmd.push("-i")
    }
    prs.on("-r", "grep recursively"){
      cmd.push("-r")
    }
    prs.on("-z", "-w", "force grep to delimit at nulbytes, rather than linefeeds (WARNING: not recommended for large files)"){
      cmd.push("-z")
    }
    prs.on("-n", "show linenumbers"){
      cmd.push("-n")
    }
  }.parse!
  str = ARGV.shift
  targets = ARGV.dup
  if str == nil then
    $stderr.printf("need to provide at least ONE argument: the string to search for!\n")
    exit(1)
  end
  pat = mkpattern(str)
  $stderr.printf("pattern: %s\n", pat)
  cmd.push("-e", pat)
  if recursive then
    cmd.push("-r")
    if targets.empty? then
      targets.push(Dir.pwd)
    end
  end
  cmd.push(*targets)
  if $stdin.tty? && !cmd.include?("-r") then
    $stderr.printf("(you didn't specify '-r' - reading from terminal atm!)\n")
  end
  exec(*cmd)
end


