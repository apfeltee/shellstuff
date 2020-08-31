#!/usr/bin/ruby

require "ostruct"
require "optparse"


DEFAULT_COMMANDS = ["bt"]
LLDB_EXE_PATH = "lldb"

class AutoGDB
  def initialize(opts)
    @opts = opts
  end

  def msg(fmt, *a, **kw)
    str = sprintf(fmt, *a, **kw)
    if @opts.verbose then
      $stderr.printf("%s\n", str)
    end
  end

  def agdb(args)
    cmd = [@opts.lldbexe]
    [@opts.cmdpre, @opts.cmdmain, @opts.cmdpost].each {|chunk|
      chunk.each{|com|
        cmd.push("-o", com.to_s)
      }
    }
    if not args.empty? then
      cmd.push("--", *args)
    end
    msg("command: %s", cmd.map(&:dump).join(" "))
    exec(*cmd)
  end
end

begin
  opts = OpenStruct.new({
    lldbexe: LLDB_EXE_PATH,
    cmdpre: ["run"],
    cmdmain: [],
    cmdpost: ["quit"],
    verbose: false,
  })
  nargv = ARGV.dup
  prs = OptionParser.new{|prs|
    prs.on("-x<exe>", "--exe=<exe>", "run <exe> instead of 'gdb' in your $PATH (i.e., wingdb64.exe)"){|v|
      opts.lldbexe = v
    }
    prs.on("-c<command>", "--command=<command>", "push command to be run after 'run' (can be used several times)"){|v|
      opts.cmdmain.push(v)
    }
    prs.on("-v", "--verbose", "enable verbose messages"){
      opts.verbose = true
    }
  }
  posit = prs.parse!(nargv)
  if opts.cmdmain.empty? then
    opts.cmdmain = DEFAULT_COMMANDS
  end
  AutoGDB.new(opts).agdb(posit)
end
