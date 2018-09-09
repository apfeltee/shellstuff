#!/usr/bin/env ruby

class String
  def number?
    return true if Float(self) rescue false
  end
end

def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  return nil
end

class ProgArgs
  def initialize(argv)
    @argv = argv
  end

  def err(*args)
    $stderr.printf("%s: error: ", File.basename($0))
    $stderr.printf(*args)
    $stderr.puts
  end

  def getArgsOfPid(pid)
    procpath = File.join("/proc", pid.to_s)
    if File.directory?(procpath) then
      cmdline = File.join(procpath, "cmdline")
      begin
        buf = []
        File.open(cmdline, "rb") do |fh|
          data = fh.read
          buf = data.split("\0")
        end
        return buf
      rescue => err
        err("cannot open %p for reading: %s", cmdline, err)
      end
    else
      err("cannot process PID %d: location %p does not exist", pid, procpath)
    end
  end

  def findAndHandleByName(name)
    err("not implemented; use 'pargs $(pgrep <processname>)' instead")
    return false
  end

  def run
    status = 0
    @argv.each do |arg|
      if arg.number? then
        npid = arg.to_i
        if cmdargs = getArgsOfPid(npid) then
          $stdout.printf("%d:\n", npid)
          cmdargs.each_with_index do |val, i|
            $stdout.printf("  argv[%d] = %p\n", i, val)
          end
        end
      else
        if not findAndHandleByName(arg) then
          err("argument %p is not a number, and no processes matching %p could be found", arg, arg)
          status = 1
        end
      end
    end
    return status
  end
end

exit(ProgArgs.new(ARGV).run)
