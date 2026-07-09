#!/usr/bin/ruby

ISWSL = ((ENV["WSL_DISTRO_NAME"] != nil) || File.directory?("/mnt/c"))
PREFIX = (if ISWSL then "/mnt/c" else "c:" end)
EXEPATH = "#{PREFIX}/cloud/gdrive/portable/devtools/il2cpp/build/deploy/net5.0/il2cpp.exe"

begin
  printf("EXEPATH=%s\n", EXEPATH)
  exec(EXEPATH, *ARGV)
end

