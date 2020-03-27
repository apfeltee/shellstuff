#!/usr/bin/ruby

require "yaml"

# sane default paths to add
DEFAULT_PATHS_TO_ADD = [
  "~/bin",
  "~/.local/bin",
  "/bin",
  "/usr/bin",
  "/usr/sbin",
  "/usr/local/bin",
  "/opt/bin",
]

class CleanEnv
  def initialize
    @statbuf = []
    install_defaults
    read_config
    clean_path
  end
  
  def addstat(path, complain=true)
    if path.start_with?("~") then
      path = File.expand_path(path)
    end
    begin
      @statbuf.push(File.stat(path))
    rescue => ex
      if complain then
        $stderr.printf("failed to push %p: (%s) %s\n", path, ex.class.name, ex.message)
      end
    end
  end

  def install_defaults
    DEFAULT_PATHS_TO_ADD.each do |dpath|
      addstat(dpath, true)
    end
  end

  def read_config
    if File.file?(dotfile = File.expand_path("~/.cleanenv.yml")) then
      (v=YAML.load_file(dotfile)).each do |path|
        $stderr.printf("yaml-config: adding %p\n", path)
        addstat(path)
      end
      p v
    end
  end

  def clean_path
    paths = ENV["PATH"].split(":")
    buf = []
    paths.each do |path|
      begin
        st = File.stat(path)
        if not @statbuf.include?(st) then
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

  def run(*cmd)
    #$stderr.printf("command: %p\n", cmd)
    exec(*cmd)
  end
end

begin
  ce = CleanEnv.new
  # get basename of $0 - which may actually be an absolute path
  selfname   = File.basename($0).gsub(/\.exe$/i, "")
  # get the actual path - getrealself returns the name of this script
  realpath   = File.absolute_path(ce.getrealself)
  # now get the basename, but sans extension
  realself   = File.basename(realpath).gsub(/\.\w+$/, "")
  # alternatively, use this environment variable
  envself    = ENV["__CLEANENV_EXECUTABLE"]
  # figure out if this script is being called as is
  # and if so, print a message and exit
  isrealself = ((realself.downcase == selfname.downcase) && (envself == nil))
  if isrealself && ARGV.empty? then
    $stderr.puts([
      "this is a wrapper for running windows binaries in cygwin that cleans the PATH environment",
      "usage:",
      "   cleanenv some/windows/program/that/conflicts/with/cygwin-paths/runme.exe someargs some-more-args ...",
      "",
    ].join("\n"))
    exit(1)
  else
    nargv = ARGV.dup
    if envself == nil then
      selfname = nargv.shift
    else
      selfname = envself
    end
    ce.run(selfname, *nargv)
  end
end
