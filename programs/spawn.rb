#!/usr/bin/ruby

def xspawn(cmdarr, **opts)
  verbose = opts[:verbose]
  $stderr.printf("xspawn: %p\n", cmdarr) if verbose 
  #pid = Process.spawn(*cmdarr)
  exec(*cmdarr)
  if not opts[:noprintpid] then
    $stdout.puts(pid)
  end
  Process.detach($$)
  exit(0)
end

def collect_cmd_flags(stop_at_word: false)
  idx = 0
  nargv = []
  opts = {}
  sawword = false
  while true do
    arg = ARGV[idx]
    if (arg == nil) then
      break
    elsif (arg == "--") then
      break
    else
      # don't parse at all if we saw a non-option
      # and if stop_at_word is set
      if sawword && stop_at_word then
        nargv.push(arg)
      else
        if (arg[0] == '-') then
          rest = arg[1 .. -1]
          # handle GNU combined opts, i.e., "-nv" -> ["-n", "-v"]
          if (arg[1] != '-') && (rest.length > 1) then
            rest.each_char do |c|
              opts[c] = true
            end
          else
            # a long option
            if (arg[1] == '-') then
              # "--opt" -> "opt"
              name = arg[2 .. -1]
              opts[name] = true
            else
              # "-o" -> "o"
              name = arg[1]
              opts[name] = true
            end
          end
        else
          sawword = true
          nargv.push(arg)
        end
      end
    end
    idx += 1
  end
  ARGV.replace(nargv)
  return opts
end

begin
  flags = collect_cmd_flags(stop_at_word: true)
  p flags
  p ARGV
  opts = {
    verbose: flags.key?("v") || flags.key?("verbose"),
    noprintpid: flags.key?("n") || flags.key?("nopid"),
  }
  if flags.key?("h") || flags.key?("help") then
    $stderr.puts([
      "spawn a process in the background (using Process.spawn).\n",
      "possible options:\n",
      "  -v --verbose  - be verbose\n",
      "  -n --nopid    - do not print pid after spawning\n",
    ].join)
    exit(0)
  end
  if ARGV.empty? then
    $stderr.printf("error: need arguments\n")
    exit(1)
  else
    xspawn(ARGV, **opts)
    exit(0)
  end

end