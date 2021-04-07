#!/usr/bin/ruby --disable-gems

$chromebin = 'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe'
$defaultflags = ["--headless", "--disable-gpu"]

def contains(arr, *things)
  things.each do |thing|
    if arr.include?(thing) then
      return true
    end
  end
  return false
end

begin
  cmd = [$chromebin, *$defaultflags]
  if ARGV.empty? then
    puts("usage: chrome <options...> <args...>")
    exit(1)
  else
    positional = []
    need_enablelogging = !contains(ARGV, "--repl")
    ARGV.each do |arg|
      # todo: process args?
      positional.push(arg)
    end
    cmd.push("--enable-logging") #if need_enablelogging
    cmd.push(*positional)
    $stderr.printf("cmd=%p\n", cmd)
    exec(*cmd)
  end
end
