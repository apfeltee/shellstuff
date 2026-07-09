#!/usr/bin/ruby

begin
  # npx @electron/asar extract app.asar files
  exec("npx", "@electron/asar", *ARGV)
end
