#!/usr/bin/env ruby

def symlink_real(from, to)
  if not File.exists?(to) then
    puts("  [ln] from %s to %s ..." % [from.inspect, to.inspect])
    File.symlink(from, to)
  end
end

def symlink_home(file)
  realpath = File.join(ENV["PWD"], file)
  bindir = File.join(ENV["HOME"], "/bin")
  dest = File.join(bindir, File.basename(realpath))
  symlink_real(realpath, dest)
end

def get_os
  return %x{uname -o}.strip.downcase
end

def is_cygwin
  return (get_os == "cygwin")
end

def is_linux
  return (get_os == "linux")
end

def do_dir(name)
  puts("Symlinking #{name} scripts ...")
  Dir.glob("#{name}/*").each do |file|
    symlink_home(file)
  end
end

do_dir("programs")
if is_cygwin then
  do_dir("cygwin")
elsif is_linux then
  do_dir("linux")
end
