#!/usr/bin/ruby

require "ostruct"
require "fileutils"

NIKTO_EXE = "c:/cloud/local/code/hackback/nikto/program/nikto.pl"
DEFAULT_FORMAT = "json"

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

def get_logdest(host)
  home = ENV["HOME"]
  if not File.directory?(home) then
    $stderr.printf("your setup is wonky: $HOME is not a directory!\n")
    exit(1)
  end
  dir = File.join(home, ".niktologs")
  if not File.directory?(dir) then
    FileUtils.mkdir_p(dir)
  end
  fname = sprintf("%s.json", host)
  return File.join(dir, fname)
end


class WrapNikto
  def initialize(opts)
    @opts = opts
    @initcmd = [NIKTO_EXE]
  end


  def run_nikto(host)
    cmd = @initcmd.dup
    cmd.push("-host", host)
    othercmd = @opts.other
    ofile = get_logdest(host)
    $stderr.printf("log file will be stored in %p\n", ofile)
    if File.file?(ofile) && (not @opts.force) then
      $stderr.printf("file already exists and '-f' not specified; aborting\n")
      return
    end
    cmd.push("-o", ofile)
    cmd.push(*othercmd)
    system(*cmd)
  end
end

begin
  tmpargv = ARGV
  newargv = []
  targethosts = []
  hadoutput = false
  isforcing = false
  ourcmd = [NIKTO_EXE]
  actualidx = 0
  nowidx = 0
  targetlogfile = nil
  while actualidx < tmpargv.length do
    arg = tmpargv[actualidx]
    nowidx = actualidx
    actualidx += 1
    if (arg == "-f") || (arg == "--force") then
      isforcing = true
    elsif (arg == "-o") then
      hadoutput = true
      targetlogfile = tmpargv[nowidx+1]
      newargv.push("-o", targetlogfile)
    elsif (arg == "-host") then
      nextarg = tmpargv[nowidx+1]
      targethosts.push(nextarg)
      # MUST be pushed back
      newargv.push("-host", nextarg)
    end
  end
  # this part ONLY runs when "-o" has been omitted.
  if !hadoutput then
    if targethosts.length == 0 then
      $stderr.printf("***error: cannot figure out target host(s)")
      exit(1)
    end
    targetname = targethosts.map{|s| s.downcase }.uniq.join
    targetlogfile = get_logdest(targetname)
    ourcmd.push("-o", targetlogfile)
  end
  ourcmd.push(*newargv)
  $stderr.printf("log file will be stored in %p\n", targetlogfile)
  if File.file?(targetlogfile) && (not isforcing) then
    $stderr.printf("file already exists and '-f' not specified; aborting\n")
    exit(1)
  end
  $stderr.printf("final nikto command: %p\n", ourcmd)
  exec(*ourcmd)
end


