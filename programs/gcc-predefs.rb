#!/usr/bin/ruby

require "optparse"

DEFAULT_EXE = "gcc"
DEFAULT_LANG = "c"

class OptionParser
  # Like order!, but leave any unrecognized --switches alone
  def order_recognized!(args)
    extra_opts = []
    begin
      order!(args) { |a| extra_opts << a }
    rescue OptionParser::InvalidOption => e
      extra_opts << e.args[0]
      retry
    end
    args[0, 0] = extra_opts
  end
end

begin
  exe = DEFAULT_EXE
  lang = DEFAULT_LANG
  op = OptionParser.new{|prs|
    prs.on("-e<exe>", "specify compiler executable (defaults to '#{DEFAULT_EXE}')"){|v|
      exe = v
    }
    prs.on("-x<lang>", "specify language (defaults to '#{DEFAULT_LANG}')"){|v|
      lang = v
    }
  }
  nargv = op.order_recognized!(ARGV)
  ourcmd = [exe]
  if !exe.match(/bcc/) then
    ourcmd.push("-x#{lang}")
    ourcmd.push("-dM")
  end
  ourcmd.push(*ARGV)
  ourcmd.push("-E", "/dev/null")
  $stderr.printf("cmd=%p\n", ourcmd)
  IO.popen(ourcmd, "rb"){|io|
    io.each_line do |ln|
      $stdout.print(ln)
      $stdout.flush
    end
  }
end
