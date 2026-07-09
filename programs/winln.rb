#!/usr/bin/ruby

require "optparse"
require "shellwords"

def getpscmd()
  return ["ruby", File.join(ENV["HOME"], "bin", "powershell")]
end

def symlink(from, to, faux)
  pscmd = getpscmd()
  cmd = ["gsudo"]
  cmd.push(*pscmd)
  cmd.push("-Command")
  cmd.push("New-Item", "-ItemType", "SymbolicLink", "-Path", to.dump, "-Target", from.dump)
  if faux then
    $stderr.printf("would run: %s\n", cmd.shelljoin)
  else
    return exec(*cmd)
  end
  return true
end

begin
  faux = false
  OptionParser.new{|prs|
    prs.on("-t", "does not run command, only prints it"){
      faux = true
    }
  }.parse!
  from = ARGV[0]
  to = ARGV[1]
  if (from == nil) || (to == nil) then
    $stderr.printf("need at least two arguments")
    exit(1)
  end
  if !symlink(from, to, faux) then
    exit(1)
  end
end

