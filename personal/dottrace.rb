#!/usr/bin/ruby

JETBRAINS_DOTTRACE_DIR = "c:/cloud/gdrive/portable/devtools/dottrace"
JETBRAINS_DOTTRACE_EXE = File.join(JETBRAINS_DOTTRACE_DIR, "dottrace.exe")

begin
  exec(JETBRAINS_DOTTRACE_EXE, *ARGV)
end


