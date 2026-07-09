#!/usr/bin/ruby

ISWSL = (ENV["WSL_DISTRO_NAME"] != nil)
WINMONO_DMCS = "c:/progra~1/mono/bin/dmcs"

begin
  if ISWSL then
    exec("/usr/bin/dmcs", *ARGV)
  else
    exec(WINMONO_DMCS, *ARGV)
  end
end


