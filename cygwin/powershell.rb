#!/usr/bin/ruby --disable-gems

$powershell_exepath = "/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
$selfname = File.basename($0)
$defaultargs = %w(
  -inputformat none
)

def abspath(path)
  #cygpath = File.absolute_path(path)
  #return cygpath.gsub(//)
  IO.popen(["cygpath", "-ma", path]) do |io|
    return io.read.strip
  end
end

begin
  rargv = []
  ARGV.each do |arg|
    if (arg[0] != '-') && arg.match(/\.ps1$/i) then
      rargv.push(abspath(arg))
    else
      rargv.push(arg)
    end
  end
  if $selfname == "powershell-noprofile" then
    $defaultargs.push("-NoProfile")
  end
  #exec "$powershell_exepath" "${nargs[@]}" "$@"
  exec(*[$powershell_exepath, *$defaultargs, *rargv])
  exit
end