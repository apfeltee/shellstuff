#!/usr/bin/ruby

def clean_path
  paths = ENV["PATH"].split(":")
  buf = []
  cygstats = [
    File.stat(File.expand_path("~/bin")),
    File.stat("/bin"),
    File.stat("/usr/bin"),
  ]
  paths.each do |path|
    begin
      st = File.stat(path)
      if not cygstats.include?(st) then
        buf.push(path)
      end
    rescue Errno::ENOENT => ex
      # skip
    end
  end
  ENV["PATH"] = buf.join(":")
end

def getrealself
  thisfile = __FILE__
  if File.symlink?(thisfile) then
    return File.readlink(thisfile)
  end
  return thisfile
end

def vexec(*cmd)
  #$stderr.printf("command: %p\n", cmd)
  clean_path
  exec(*cmd)
end

begin
  # get basename of $0 - which may actually be an absolute path
  selfname   = File.basename($0).gsub(/\.exe$/i, "")
  # get the actual path - getrealself returns the name of this script
  realpath   = File.absolute_path(getrealself)
  # now get the basename, but sans extension
  realself   = File.basename(realpath).gsub(/\.\w+$/, "")
  # alternatively, use this environment variable
  envself    = ENV["__CLEANENV_EXECUTABLE"]
  # figure out if this script is being called as is
  # and if so, print a message and exit
  isrealself = ((realself.downcase == selfname.downcase) && (envself == nil))
  if isrealself then
    $stderr.puts([
      "this is a wrapper for running windows binaries in cygwin that cleans the PATH environment"
    ].join("\n"))
    exit(1)
  else
    if envself != nil then
      selfname = envself
    end
    vexec(selfname, *ARGV)
  end
end



