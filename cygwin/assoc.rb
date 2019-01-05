#!/usr/bin/ruby

def assoc(ext)
  cmd = ["c:/windows/system32/cmd.exe", "/c", "assoc", ext]
  system(*cmd)
end

begin
  if ARGV.empty? then
    assoc("/?")
  else
    ARGV.each do |arg|
      assoc(arg)
    end
  end
end

