#!/usr/bin/ruby --disable-gems

moreopts = []
conffile = File.join(ENV["HOME"], ".clang-format")
if File.file?(conffile) then
  require "json"
  require "yaml"
  data = YAML.load(File.read(conffile))
  json = JSON.dump(data)
  moreopts.push("-style=#{json}")
else
  $stderr.printf("clang-format: no config file at %p\n", conffile)
end

newargv = [*moreopts, *ARGV]
ENV["__WINLLVM_EXECUTABLE"] = "clang-format"
ARGV.replace(newargv)
load "C:/cygwin/home/sebastian/dev/clangfix/winllvm-exec.rb"
