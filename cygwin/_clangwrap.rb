#!/usr/bin/env ruby

program = $0
progbase = File.basename(program)

if not progbase.match(/^clang/) then
  raise Error, "nope"
else
  args = []
  needoflag = true
  notcc1 = true
  ARGV.each do |fl|
    if fl.match(/\-cc/) then
      needoflag = false
      notcc1 = false
    elsif notcc1 && fl.match(/\-o/) then
      needoflag = false
    end
    args << fl
  end
  args << "-oa.exe" if needoflag
  cmd = ["/usr/bin/#{progbase}", *args]
  exec(*cmd)
end
