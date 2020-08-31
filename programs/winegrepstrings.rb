#!/usr/bin/ruby

#
# constructs patterns to search for wine-like strings, such as:
#
#   static const WCHAR poop[] = {'w','i','n','e','h','q', 0};
#
# don't ask me WHY wine specifies strings this way. that's just how it is, i guess.
# maybe they're masochistic? who knows.
#

require "ostruct"
require "optparse"

def encchar(ch)
  if ch == "'" then
    return '\\\''
  end
  #ch.dump[1 .. -2]
  return Regexp.quote(ch)
end

def enchex(ch)
  return sprintf("0x%2X", ch.ord)
end

def encdec(ch)
  return ch.ord
end

def mkpattern(instr, mode)
  buf = []
  instr.each_char do |ch|
    case mode
      when :char
        e = encchar(ch).to_s
        # include wide character specifier - if it exists
        buf.push("L?'" + e + "'")
      when :hex
        e = enchex(ch).to_s
        buf.push(e)
      when :dec
        e = encdec(ch).to_s
        buf.push(e)
    end
  end
  # this isn't going to work with linefeeds!
  return buf.join('\s*,\s*')
end

begin
  opts = OpenStruct.new({
    recursive: false,
    encmode: :char,
  })
  cmd = cmd = ["grep", "--color=auto", "-P"]
  OptionParser.new{|prs|
    prs.on("-i", "ignore case distinctions"){
      cmd.push("-i")
    }
    prs.on("-r", "grep recursively"){
      cmd.push("-r")
      opts.recursive = true
    }
    prs.on("-z", "-w", "force grep to delimit at nulbytes, rather than linefeeds (WARNING: not recommended for large files)"){
      cmd.push("-z")
    }
    prs.on("-n", "show linenumbers"){
      cmd.push("-n")
    }
    prs.on("-x", "--hex", "encode characters as hexadecimals"){
      opts.encmode = :hex
    }
    prs.on("-d", "--dec", "encode characters as decimals"){
      opts.encmode = :dec
    }
  }.parse!
  str = ARGV.shift
  targets = ARGV.dup
  if str == nil then
    $stderr.printf("need to provide at least ONE argument: the string to search for!\n")
    exit(1)
  end
  pat = mkpattern(str, opts.encmode)
  $stderr.printf("pattern: %s\n", pat)
  cmd.push("-e", pat)
  if opts.recursive then
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


