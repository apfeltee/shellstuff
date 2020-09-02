#!/usr/bin/ruby

def msg(vb, fmt, *args)
  if vb then
    $stderr.printf("-- %s\n", sprintf(fmt, *args))
  end
end

def cget(opts, urls, vb)
  cmd = ["curl", "-OL", "--progress-bar", *opts]
  msg(vb, "options: %p", opts)
  # without this, curl will print every other url after the first to stdout...
  if urls.length > 1 then
    excode = 0
    urls.each do |url|
      msg(vb, "splitting up call to curl for %p", url)
      if not system(*[*cmd, url]) then
        msg(vb, "returned bad exit code, likely may have failed")
        excode += 1
      end
    end
    return (if (excode > 0) then false else true end)
  else
    msg(vb, "exec()ing call to curl")
    exec(*cmd)
  end
  return true
end

begin
  if ARGV.empty? then
    puts("cget is a convenience wrapper for 'curl -OL' ('-O' = 'remote filename', '-L' = 'follow redirects')")
    puts("usage: cget <url> [<another url> ...]")
  else
    urls = []
    opts = []
    verbose = false
    ARGV.each do |arg|
      if arg[0] == '-' then
        if arg == "-v" then
          verbose = true
          # exchanging '-v' for '-D-', which dumps headers to stdout
          # curl's '-v' is VERY verbose!
          opts.push("-D-")
        else
          opts.push(arg)
        end
      else
        urls.push(arg)
      end
    end
    exit(cget(opts, urls, verbose))
  end
end
