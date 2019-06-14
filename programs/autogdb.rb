#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "pry-byebug"

DEFAULT_COMMANDS = ["set confirm off", "bt"]

# gdb -ex run -ex bt -ex quit --args ./a.exe prime.t
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
    cmd = [@opts.gdbexe, "-q"]
    [@opts.cmdpre, @opts.cmdmain, @opts.cmdpost].each {|chunk|
      chunk.each{|com|
        cmd.push("-ex", com.to_s)
      }
    }
    cmd.push("--args", *args)
    msg("command: %s", cmd.map(&:dump).join(" "))
    exec(*cmd)
  end
end

begin
  opts = OpenStruct.new({
    gdbexe: "gdb",
    # commands that are run before commands added via '-c'
    cmdpre: ["run"],

    # commands that are 
    cmdmain: [],

    cmdpost: ["quit"],

    verbose: false,
  })
  nargv = ARGV.dup
  prs = OptionParser.new{|prs|
    prs.on("-x<exe>", "--exe=<exe>", "run <exe> instead of 'gdb' in your $PATH (i.e., wingdb64.exe)"){|v|
      opts.gdbexe = v
    }
    prs.on("-c<command>", "--command=<command>", "push command to be run after 'run' (can be used several times)"){|v|
      opts.cmdmain.push(v)
    }
    prs.on("-v", "--verbose", "enable verbose messages"){
      opts.verbose = true
    }
  }
  #binding.pry
  posit = prs.parse!(nargv)
  if opts.cmdmain.empty? then
    opts.cmdmain = DEFAULT_COMMANDS
  end
=begin
  Hash.new({
    posit: posit,
    nargv: nargv,
    ARGV: ARGV,
  }).each do |k, v|
    $stderr.printf("%s = %p\n", k, v)
  end
=end
  AutoGDB.new(opts).agdb(posit)
end
