#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "pry-byebug"

DEFAULT_COMMANDS = [
  "set confirm off",
  "set pagination off",
  "set print pretty on",
  "set print object on",
  #"info frame",
  "info locals",
  "info args",
  #"bt -full",
  "bt",
]

class OptionParser
  # Like order!, but leave any unrecognized --switches alone
  def order_recognized!(args)
    extra_opts = []
    begin
      order!(args) do |a|
        extra_opts.push(a)
      end
    rescue OptionParser::InvalidOption => e
      extra_opts.push(e.args[0])
      retry
    end
    args[0, 0] = extra_opts
    return extra_opts
  end
end

# gdb -ex run -ex bt -ex quit --args ./a.exe prime.t
class AutoGDB
  def initialize(opts)
    @opts = opts
  end

  def msg(fmt, *a, **kw)
    if @opts.verbose then
      str = sprintf(fmt, *a, **kw)
      $stderr.printf("%s\n", str)
    end
  end

  def agdb(args)
    cmd = [@opts.gdbexe, "-q"]
    #if !@opts.dropin then
      [@opts.cmdpre, @opts.cmdmain, @opts.cmdpost].each {|chunk|
        chunk.each{|com|
          cmd.push("-ex", com.to_s)
        }
      }
    #end
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

    cmdpost: [],

    verbose: true,
  })
  nargv = ARGV

=begin
  ai = 0
  while (ai < nargv.length) do
    arg = nargv[ai]
    ai += 1
    first = arg[0]
    if first == '-' then
      second = arg[1]
      len = arg.len
      if second == 'e' then
        if len == 2 then
          val = nargv[ai+1]
          ai += 1
        else
          val = arg[2 .. -1]
        end
        opts.gdbexe
  end
=end
  prs = OptionParser.new{|prs|
    #binding.pry
    prs.on("-x<exe>", "--exe=<exe>", "run <exe> instead of 'gdb' in your $PATH (i.e., wingdb64.exe)"){|v|
      opts.gdbexe = v
    }
    prs.on("-c<command>", "--command=<command>", "push command to be run after 'run' (can be used several times)"){|v|
      opts.cmdmain.push(v)
    }
    prs.on("-v", "--verbose", "enable verbose messages"){
      opts.verbose = true
    }
    prs.on("-d", "drop-in (as if running 'gdb --args ...')"){
      opts.dropin = true
    }
    prs.on("-h", "--help"){
      puts(prs.help)
      exit(1)
    }
  }
  begin
    prs.order!(nargv)
  rescue OptionParser::InvalidOption => io
    nargv = io.recover(nargv)
    $stderr.printf("recovered: nargv: %p\n", nargv)
  rescue => e
    raise "Argument parsing failed: #{e.to_s()}"
  end
  posit = nargv

  if !opts.dropin then
    opts.cmdpost.push("quit")
  end
  p posit
  if opts.cmdmain.empty? then
    opts.cmdmain = DEFAULT_COMMANDS
  end
  AutoGDB.new(opts).agdb(posit)
end
