#!/usr/bin/env ruby

require "pp"
require "optparse"
require "shellwords"

INITIAL_CURSEWORDS = %w(fuck shit crap damn bastard idiot)

class CurseWords
  def initialize
    @cursewords = INITIAL_CURSEWORDS
    @opts = %w(-A3 -inP --color=always)
    @realargs = []
    @prs = OptionParser.new{|prs|
      prs.on("-w <s>", "--word=<s>", "Additional curse word"){|v|
        @cursewords.push(v)
      }
    }
    @prs.parse!
  end

  def msg(str)
    $stderr.puts("curse:msg: #{str}")
  end

  def run
    if ARGV.length > 0 then
      cursepat = "(#{@cursewords.map{|s| s.shellescape }.join("|")})"
      cmd = ["grep", "-r", *@opts, cursepat, *@realargs]
      msg "using pattern #{cursepat.inspect}"
      msg "running #{cmd}, please be patient ..."
      exec(*cmd)
    else
      puts(@prs.help)
    end
  end
end

begin
  CurseWords.new.run
end
