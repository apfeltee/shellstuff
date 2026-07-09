#!/usr/bin/ruby

# per man page:

EXTRAFLAGS = <<__eos__
  #--tool=callgrind
  #--dump-instr=yes
  #--simulate-cache=yes
  #--collect-jumps=yes
  #--collect-atstart=no
  --instr-atstart=no
__eos__

def parseflagstr(src)
  r = []
  src.split(/\n/).each do |s|
    s.strip!
    next if s.empty?
    next if s.match?(/^#/)
    r.push(s)
  end
  return r
end

begin
  extra = parseflagstr(EXTRAFLAGS)
  argv = ARGV
  cmd = ['valgrind', *extra, *argv]
  exec(*cmd)
end
