#!/usr/bin/ruby

ISWSL = (ENV["WSL_DISTRO_NAME"] != nil)
WINMONO_MCS = "c:/progra~1/mono/bin/mcs"

begin
  if ISWSL then
    exec("/usr/bin/mcs", *ARGV)
  else
    exec(WINMONO_MCS, *ARGV)
  end
end

