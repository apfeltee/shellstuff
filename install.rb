#!/usr/bin/env ruby

def symlink_real(from, to)
  if not File.exists?(to) then
    printf("  [ln] from %p to %p ...\n", from, to)
    File.symlink(from, to)
  end
end

def symlink_home(file)
  bindir = File.join(ENV["HOME"], "/bin")
  abspath = File.absolute_path(file)
  basename = File.basename(abspath)
  finalname = basename.gsub(/\.\w+$/, "")
  dest = File.join(bindir, finalname)
  if File.symlink?(dest) then
    File.delete(dest)
  end
  symlink_real(abspath, dest)
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
  puts("Symlinking #{name} scripts/programs ...")
  Dir.glob("#{name}/*").each do |file|
    symlink_home(file)
  end
end


## first "install" native programs...
Dir.chdir "native" do
  if system("make") then
    system("make install")
  end
end

## then, process scripts ...
do_dir("programs")
if is_cygwin then
  do_dir("cygwin")
elsif is_linux then
  do_dir("linux")
end
