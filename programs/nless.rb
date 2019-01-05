#!/usr/bin/ruby --disable-gems

require "open3"

def run(*incmd)
  ret = Open3.pipeline([*incmd], ['less'])
  #$stderr.printf("ret=%p\n", ret)
end

def main(item)
  rc = 0
  tmp = item.downcase
  if tmp.match(/^(https?|s?ftp|gopher):\/\//) then
    run("curl", "-q", "--stderr", "/dev/null",  "-L", item)
  else
    if File.file?(item) then
      run("cat", item)
    else
      $stderr.printf("not a file: %p\n", item)
      rc += 1
    end
  end
  return rc
end

begin
  rc = 0
  if ARGV.empty? then
    puts("usage: nless <path|url> ...")
  else
    ARGV.each do |item|
      rc += main(item)
    end
  end
  exit(rc)
end
