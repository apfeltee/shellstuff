#!/usr/bin/ruby

#cmd /c dir /x | grep -P '[a-zA-Z0-9-]{6}~.\.\w\w\w' -o
#example output of 'cmd /c dir /x':
=begin
 Volume in drive C is Windows
 Volume Serial Number is 8CB9-9023

 Directory of C:\cygwin\home\sebastian\dev\shellstuff

18.04.2018  21:18    <DIR>                       .
18.04.2018  21:18    <DIR>                       ..
16.02.2018  06:27    <DIR>          GIT~1        .git
16.02.2018  06:27                17 GITIGN~1     .gitignore
18.04.2018  21:18    <DIR>                       cygwin
16.02.2018  06:27             1.074              install.rb
16.02.2018  06:27    <DIR>                       linux
16.02.2018  06:27    <DIR>                       native
08.03.2018  09:27    <DIR>                       programs
16.02.2018  06:27             2.627              README.md
18.04.2018  21:16               254              shortls.ps1
               4 File(s)          3.972 bytes
               7 Dir(s)  62.283.448.320 bytes free
=end

EXE_CMDEXE = "c:/windows/system32/cmd.exe"

def run(*cmd)
  return IO.popen([*cmd]).read.strip
end

def get_winpath(item)
  return run("cygpath", "-wa", item)
end

$rx = /\b(?<short>[a-zA-Z0-9-]{1,6}~.?(\.\w\w\w)?)\b/
#$rx = /\b(\S{1,8}(\.\S{1,3})?)\b/
#$rx = /^\d\d\.\d\d\.\d{4}\s+\d\d:\d\d/

=begin
["18.04.2018", "21:38", "<DIR>", "."]
["18.04.2018", "21:38", "<DIR>", ".."]
["16.02.2018", "06:27", "<DIR>", "GIT~1", ".git"]
["16.02.2018", "06:27", "17", "GITIGN~1", ".gitignore"]
["18.04.2018", "21:38", "1", "AFILEW~1.TXT", "a", "file", "with", "spaces.txt"]
["18.04.2018", "21:18", "<DIR>", "cygwin"]
["16.02.2018", "06:27", "1.074", "install.rb"]
["16.02.2018", "06:27", "<DIR>", "linux"]
["16.02.2018", "06:27", "<DIR>", "native"]
["08.03.2018", "09:27", "<DIR>", "programs"]
["16.02.2018", "06:27", "2.627", "README.md"]
["18.04.2018", "21:36", "1", "SHITE-~1.PDF", "shite-fuck0r-cocksdsfasfdsafasdf.pdf"]
["18.04.2018", "21:16", "254", "shortls.ps1"]
=end
def do_list(dir)
  winp = get_winpath(dir)
  run(EXE_CMDEXE, "/c", "dir", "/x", winp).gsub(/\r/, "").each_line do |line|
    m = line.match($rx)
    #p m
    if m then
      yield m[1]
    end
  end
end

begin
  dir = (ARGV[0] || ".")
  do_list(dir) do |item|
    puts item
  end
end