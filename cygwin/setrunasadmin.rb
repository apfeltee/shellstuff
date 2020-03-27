#!/usr/bin/ruby -w

=begin
regpath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
filename = "C:\temp\compatmodel\iconsext.exe"
REG ADD $regpath /v $filename /t REG_SZ /d "WINXPSP3 RUNASADMIN" /f
=end

REGEXE = 'c:/windows/system32/reg.exe'
COMPATREG = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'

def vsystem(*cmd)
  $stderr.printf("cmd = %p\n", cmd)
  return system(*cmd)
end

def stdcmd(*cmd, mode: "rb")
  return IO.popen(cmd, mode){|io| io.read }
end

def winpath(file)
  realpath = stdcmd("realpath", "-e", file).strip
  return stdcmd("cygpath", "-wa", realpath).strip
end

# reg("add", )
def reg(verb, path, *things)
  return vsystem(REGEXE, verb, path, *things)
end

def set_compatflags(file, *flags)
  return reg("add", COMPATREG, "/v", winpath(file), "/t", "REG_SZ", "/d", "$ " + flags.map(&:upcase).join(" "), "/f")
end

begin
  ec = 0
  if ARGV.empty? then
    $stderr.printf("%s <file> ...\n", File.basename($0))
    exit(1)
  else
    ARGV.each do |file|
      if not File.file?(file) then
        $stderr.printf("setrunasadmin: not a file: %p\n", file)
      else
        if not file.match?(/\.exe$/) then
          $stderr.printf("setrunasadmin: can only used with .exe files\n")
        else
          if not set_compatflags(file, "runasadmin") then
            $stderr.printf("setrunasadmin: command failed!\n")
            ec += 1
            exit
          end
        end
      end
    end
    exit(ec > 0 ? 1 : 0)
  end
end