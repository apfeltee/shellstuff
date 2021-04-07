#!/usr/bin/env ruby

require "fileutils"

def chdir(dir, &b)
  path = File.join(__dir__, dir)
  if File.directory?(path) then
    begin
      Dir.chdir(path, &b)
    rescue => ex
      # apparently this will/might happen if Dir.chdir() (or rather, chdir() in general) is
      # being called from a directory that was deleted. this sounds silly, so:
      #
      # mkdir blah
      # cd blah
      # (go to another tab, and rmdir blah)
      # (go back to where you cd'd into blah)
      # ruby -e 'Dir.chdir(".")'
      # -e:1:in `chdir': No such file or directory @ dir_s_chdir - .
      #
      # i wonder if that's true for Linux, also.
      $stderr.printf("bug in chdir: (%s) %s\n", ex.class.name, ex.message)
    end
  end
end

def glob(pat, &b)
  Dir.glob(File.join(__dir__, pat), &b)
end

def symlink_real(from, to)
  if not File.exists?(to) then
    printf("  [ln] from %p to %p ...\n", from, to)
    File.symlink(from, to)
  end
end

def symlink_home(file)
  bindir = File.join(ENV["HOME"], "/bin")
  if not File.directory?(bindir) then
    FileUtils.mkdir_p(bindir)
  end
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
  glob(File.join(name, "*")).each do |file|
    symlink_home(file)
  end
end


## first "install" native programs...
chdir("native") do
  if File.file?("Makefile") && system("make") then
    system("make install")
  end
end

## then, process scripts ...
do_dir("programs")
do_dir("others")
if is_cygwin then
  do_dir("cygwin")
elsif is_linux then
  do_dir("linux")
end
