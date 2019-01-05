#!/usr/bin/ruby --disable-gems

def wrun(cmd)
  iter = 0
  lastret = false
  while true do
    if (lastret = system(*cmd)) == true then
      return iter, lastret
    end
    iter += 1
  end
  return iter, lastret
end

begin
  i = 0
  rt = true
  if ARGV.empty? then
    $stderr.puts("usage: wrun <command> [<options, arguments, ...>]")
  else
    begin
      i, rt = wrun(ARGV)
    ensure
      $stderr.printf("command was run %d times\n", i+1)
      exit(rt == true ? 0 : 1)
    end
  end
end

