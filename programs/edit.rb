#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "open3"
require "find"

# this is dumb, but works for me. you might want to change it, though
if not ENV["KDE_SESSION_UID"].nil? then
  $EDITOR = "/usr/bin/kate"
else
  $EDITOR = "c:/progra~2/notepad++/notepad++.exe"
end

# this is where you can specify arguments that will be passed
# to $EDITOR everytime.
$EDARGS = []

# how many arguments on average to use. 128 seems like a sensible default
$MAXARGS = 128

def shell(*args, &callback)
  Open3.popen3(*args) do |stdin, stdout, stderr|
    if callback then
      callback.call(stdin, stdout, stderr)
    end
  end
end

class File
  def self.followlink(path)

  end
end

class OpenEditor
  def initialize(opts)
    @opts = opts
    @is_cygwin = is_cygwin
    @editor = $EDITOR
    @editme = []
  end

  def complain(fmt, *args)
    str = (
      if args.empty? then
        fmt
      else
        sprintf(fmt, *args)
      end
    )
    $stderr.printf("warning: %s\n", str)
  end

  def is_cygwin
    shell("uname", "-s") do |_, stdout, _|
      return stdout.read.downcase.match(/cygwin/)
    end
  end

  def is_virtual(path)
    if path.match(/^(https?|ftp|file):/) then
      return true
    end
    return false
  end

  def get_realpath(path)
    begin
      tmp = File.readlink(path)
      if File.exist?(tmp) then
        path = tmp
      end
    rescue
    end
    return File.realpath(path)
  end

  def get_windowspath(path)
    subrx = /^\/cygdrive\/(\w)\//
    path = get_realpath(path.gsub(/^\\\?\?\\/, ""))
    if @is_cygwin then
      # in this case, path is eg "/cygdrive/c/some/long/path/somefile.ext" 
      if path.match(subrx) then
        return path.gsub(subrx, '\1:/').gsub(/\//, '\\')
      end
      shell("cygpath", "-wa", path) do |stdin, stdout, stderr|
        return stdout.read.strip
      end
    else
      return path
    end
  end

  def calleditor(paths)
    selfcmd = [@editor, *$EDARGS]
    shellcmd = [*selfcmd, *paths]
    $stderr.printf("calling %p with:\n", selfcmd)
    paths.each do |pa|
      $stderr.printf(" + %p\n", pa)
    end
    system(*shellcmd)
  end

  def editall(paths)
    tmp = []
    ci = 0
    palen = paths.length
    paths.each do |pa|
      tmp.push(pa)
      ci += 1
      if (ci == $MAXARGS) || ((palen <= $MAXARGS) && (ci >= palen)) then
        calleditor(tmp)
        tmp = []
        ci = 0
      end
    end
    calleditor(tmp) unless tmp.empty?
  end

  def walkdir(path)
    Find.find(path) do |item|
      next unless File.file?(item)
      check(item, true)
    end
  end

  def check(path, isrec=false)
    if is_virtual(path) then
      @editme.push(path)
    elsif File.file?(path) then
      @editme.push(get_windowspath(path))
    else
      if File.directory?(path) then
        if @opts.recursive then
          walkdir(path)
        else
          complain("file %p is a directory and '--recursive' was not specified", path)
        end
      elsif not File.exist?(path) then
        complain("file %p does not exist!", path)
      else
        complain("file %p cannot be opened because it is not a regular file", path)
      end
    end
  end

  def main(argv)
    argv.each do |path|
      check(path)
    end
    if @editme.length > 0 then
      editall(@editme)
    else
      warn("nothing to do")
    end
  end
end

begin
  opts = OpenStruct.new({
    recursive: false,
  })
  OptionParser.new{|prs|
    prs.on("-r", "--recursive", "when argument is a directory, walk recursively"){|_|
      opts.recursive = true
    }
  }.parse!
  OpenEditor.new(opts).main(ARGV)
end

