#!/usr/bin/ruby

require "optparse"

class ProgOpen
  def initialize
    @todo = []
  end

  def vsystem(*shargs)
    #$stderr.puts("open: system(#{shargs.map(&:inspect).join(", ")})")
    return system(*shargs)
  end

  def impl_cmdstart(shargs)
    vsystem("cmd", "/c", "start", *shargs)
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
      if arg.match(/^file:\/\/\/?[a-zA-Z]\:/) then
        @todo.push(proc{ impl_cmdstart(arg) })
      end
      @todo.push(proc{ impl_cygstart(arg) })
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
  opts = {concurrent: false}
  prs = OptionParser.new {|prs|
    prs.on("-c", "--[no-]concurrent", "run every command concurrently"){|v|
      opts[:concurrent] = v
    }
  }
  prs.parse!
  if ARGV.empty? then
    $stderr.puts(prs.help)
  else
    progo = ProgOpen.new
    progo.add(ARGV)
    begin
      if opts[:concurrent] then
        progo.run_concurrent
      else
        progo.run_normal
      end
    end
  end
end
