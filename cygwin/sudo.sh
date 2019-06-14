#!/usr/bin/ruby
#exec "$@"

begin
  # cygstart --action=runas
  cmd = ["cygstart", "--action=runas", *ARGV]
  exec(*cmd)
end