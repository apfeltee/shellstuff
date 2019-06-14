#!/usr/bin/ruby

PHANTOMJS_EXE = "c:/cloud/gdrive/portable/devtools/phantomjs/bin/phantomjs.exe"

def cygpath(path)
  IO.popen(["cygpath", "-ma", path]) do |fh|
    return fh.read.strip
  end
end

def fix_args(argv)
  nargv = []
  argv.each do |arg|
    if arg[0] == '-' then
      nargv.push(arg)
    else
      if File.exist?(arg) then
        nargv.push(cygpath(arg))
      else
        nargv.push(arg)
      end
    end
  end
  return nargv
end


cmd = [PHANTOMJS_EXE, "--debug=true", *fix_args(ARGV)]
$stderr.printf("cmd=%p\n", cmd)
exec(*cmd)
