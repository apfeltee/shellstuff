#!/usr/bin/ruby

begin
  # gcc -fpreprocessed -dD -E test.c
  argv = ARGV
  if argv.empty? then
    # if no args given, force reading from stdin
    argv.push("-xc++", "-")
  end
  # -Wp,-w disables preprocessor warnings, stuff like redefinition, etc
  exec("gcc", "-Wp,-w", "-fpreprocessed", "-dD", "-E", *argv)
end



