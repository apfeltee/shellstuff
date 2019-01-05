#!/usr/bin/ruby

def ftype(typ=nil)
  cmd = ["c:/windows/system32/cmd.exe", "/c", "ftype"]
  if typ != nil then
    cmd.push(typ)
  end
  system(*cmd)
end

begin
  if ARGV.empty? then
    ftype()
  else
    ARGV.each do |arg|
      ftype(arg)
    end
  end
end



