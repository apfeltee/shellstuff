#!/usr/bin/ruby

prefix = "c:"
if File.file?("/etc/ld.so.conf.d/ld.wsl.conf") then
  prefix="/mnt/c"
end   
ILSPY_HOME = "#{prefix}/cloud/gdrive/portable/devtools/ilspy"
ILSPY_EXE = File.join(ILSPY_HOME, "ilspy.exe")

begin
  exec(ILSPY_EXE, *ARGV)
end

