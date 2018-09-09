#!/usr/bin/ruby --disable-gems

#CSC_EXE = "c:/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe"
CSC_EXE = "c:/Users/sebastian/.nuget/packages/microsoft.net.compilers/2.3.2/tools/csc.exe"

def is_option(arg)
  return ((arg[0] == '-'))
end

def is_drivepath(arg)
  return ((arg[0].match(/[a-z0-9]/i)) && (arg[1] == ':'))
end

def is_cygpath(arg)
  if arg.start_with?("/cygdrive/") then
    return true
  end
  return false
end

def fixpath(arg, cyg: false, prefix: "/cygdrive/")
  if cyg then
    buf = String.new
    prefix = "/cygdrive/"
    tmp = arg[prefix.length .. -1].chars
    letter = tmp.shift
    buf = "#{letter}:#{tmp.join}"
    return fixpath(buf, cyg: false)
  end
  return arg.gsub("/", "\\\\")
end

nargv = []
ARGV.each do |arg|
  #if (arg[0] == '-') || ((arg[0]))
  if is_option(arg) then
    nargv.push(arg)
  else
    tmp = (is_cygpath(arg) ? fixpath(arg, cyg: true) : fixpath(arg))
    nargv.push(tmp)
  end
end

cmd = ["cmd", "/c", CSC_EXE, *nargv]
p cmd
exec(*cmd)
