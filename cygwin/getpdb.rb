#!/usr/bin/ruby

require "shellwords"
# /cygdrive/c/devel/winsdk/Debuggers/x64/symchk.exe  c:/Windows/SysWOW64/cmd.exe /oc .

SYMCHK = "c:/devel/winsdk/Debuggers/x64/symchk.exe"

def getpdb(inexe, outdir)
  sh = [SYMCHK, inexe, "/oc", outdir]
  if not system(*sh) then
    $stderr.puts("command failed: #{sh.shelljoin}")
  end
end

begin
  selfname = File.basename(__FILE__)
  if ARGV.empty? then
    $stderr.puts("usage: #{selfname} [<exe> ...] <outputdirectory>")
    exit(1)
  else
    outdir = nil
    if ARGV.length == 1 then
      outdir = "."
    else
      outdir = ARGV.pop
      if not File.directory?(outdir) then
        $stderr.puts("Last argument MUST be a directory")
        exit(1)
      end
    end
    ARGV.each do |arg|
      getpdb(arg, outdir)
    end
  end
end
