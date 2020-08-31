#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "find"

class VSIncludeGrep
  REQUIREDENVS = %w(
    INCLUDE IFCPATH
    LIB LIBPATH
  )

  def initialize(a0, opts)
    @a0 = a0
    @opts = opts
    @dirs = []
    dirs = []
    REQUIREDENVS.each do |name|
      @dirs.push(*getdirs(name))
    end
  end

  def getdirs(name)
    val = ENV[name]
    if val == nil then
      $stderr.printf("%s: required environment variable %p is not set - maybe you need to run loadvs?\n", @a0, name)
      exit(1)
    end
    rt = []
    val.split(";").each do |str|
      str.strip!
      next if str.empty?
      if File.exist?(str) then
        if File.directory?(str) then
          if not File.file?(File.join(str, ".notavsdir")) then
            rt.push(str)
          end
        else
          $stderr.printf("%s: getdirs(%p): path %p exists, but not a directory!\n", @a0, name, str)
        end
      end
    end
    return rt
  end

  def main(rx)
    $stderr.printf("vsincgrep: searching %d directories\n", @dirs.length)
    cmd = ["grep", "-r"]
    if @opts.uncase then
      cmd.push("-i")
    end
    if @opts.isregex then
      cmd.push("-P")
    else
      cmd.push("-F")
    end
    cmd.push(rx)
    cmd.push(*@dirs)
    exec(*cmd)
  end

end

begin
  opts = OpenStruct.new({
    uncase: false,
    isregex: true,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-i", "--caseinsensitive", "ignore cae"){
      opts.uncase = true
    }
    prs.on("-F", "--verbatim", "pattern is to be treated verbatim"){
      opts.isregex = false
    }
  }.parse!
  a0 = File.basename($0)
  vsinc = VSIncludeGrep.new(a0, opts)
  if ARGV.empty? then
    $stderr.printf("usage: %s [<opts>] <pattern>\n", a0)
    exit(1)
  elsif ARGV.length > 1 then
    $stderr.printf("%s: multiple patterns not (yet) supported. sorry\n", a0)
    exit(1)
  else
    vsinc.main(ARGV[0])
  end
end

