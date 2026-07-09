#!/usr/bin/ruby

begin
  # cygstart --action=runas
  cmd = ["cygstart", "--action=runas", *ARGV]
  exec(*cmd)
end