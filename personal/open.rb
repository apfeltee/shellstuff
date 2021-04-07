#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "~/dev/gems/lib/cygpath.rb"

class ProgOpen
  def initialize(opts)
    @todo = []
    @opts = opts
  end

  def vsystem(*shargs)
    $stderr.puts("open: system(#{shargs.map(&:inspect).join(", ")})")
    return system(*shargs)
  end



  def impl_cmdstart(shargs)
    nargs = []
    if @opts.resolvepaths then
      shargs.each do |itm|
        if File.exist?(itm) then
          nargs.push(Cygpath.cyg2win(itm))
        else
          nargs.push(itm)
        end
      end
    else
      nargs = shargs
    end
    vsystem("cmd", "/c", "start", *nargs)
  end

  def impl_cygstart(shargs)
    #p [:shargs, shargs]
    if shargs.length == 1 then
      arg = shargs[0]
      if File.directory?(arg) || File.file?(arg) then
        # get full, canonical path...
        # readlink seems to work only sometimes for whatever reason
        expanded = File.expand_path(arg)
        newpath = %x{realpath -L #{arg.inspect}}.strip
        #puts "restored #{arg.inspect} to #{newpath.inspect}"
        shargs = [newpath]
      end
    end
    vsystem("cygstart", "-v", *shargs)
  end

  def impl_xdgopen(shargs)
    shargs.each do |arg|
      vsystem("xdg-open", arg)
    end
  end

  def impl_kdeopen(shargs)
    
  end

  def add(args)
    args.each do |arg|
      # check if it's a file:/// url from chrome; for
      # example, "file:///C:/somedir/whatever" gets treated by
      # cygstart as "/cygdrive/c/Cygwin/C:/somedir/whatever", even though
      # it should be "/cygdrive/c/somedir/whatever".
      # probably a bug, but... y'know, Not My Job [tm].
      if arg.match(/^file:\/\/\/?[a-zA-Z]\:/) || @opts.usecmd then
        @todo.push(proc{ impl_cmdstart([arg]) })
      else
        @todo.push(proc{ impl_cygstart([arg]) })
      end
    end
  end

  def run_normal
    @todo.each do |task|
      task.call
    end
  end

  def run_concurrent
    threads = @todo.map{|task| Thread.new{ task.call } }
    threads.each do |th|
      th.join
    end
  end
end

begin
  opts = OpenStruct.new({
    concurrent: false
  })
  prs = OptionParser.new {|prs|
    prs.on("-c", "--[no-]concurrent", "run every command concurrently"){|v|
      opts.concurrent = v
    }
    prs.on("-f", "--[no-]resolve", "resolve file path(s)"){|v|
      opts.resolvepaths = v
    }
    prs.on("-s", "--cmd", "use cmd /c start"){
      opts.usecmd = true
    }
  }
  prs.parse!
  if ARGV.empty? then
    $stderr.puts(prs.help)
  else
    progo = ProgOpen.new(opts)
    progo.add(ARGV)
    begin
      if opts.concurrent then
        progo.run_concurrent
      else
        progo.run_normal
      end
    end
  end
end
