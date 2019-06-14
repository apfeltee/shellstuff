#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "find"

def fail(msg, *a, **kw)
  str = sprintf(msg, *a, **kw)
  $stderr.printf("ERROR: %s\n", str)
  exit(1)
end

def isdotp(path)
  return (
    ((path == ".")  || (File.stat(path) == File.stat("."))) ||
    ((path == "..") || (File.stat(path) == File.stat("..")))
  )
end

def dotify(path, replacementchar)
  dir = File.dirname(path)
  base = File.basename(path)
  newbase = base.gsub(/[\'\"\(\)\[\]\{\}]/, "").gsub(/[^a-z0-9\-\.]/i, replacementchar)
  #msg("pre-while: newbase=%p\n", newbase)
  while ((newbase[0] == replacementchar) || (newbase[0] == ".")) do
    newbase = newbase[1 .. -1]
  end
  dupstr = (replacementchar * 2)
  dupre = Regexp.new(Regexp.quote(dupstr))
  while newbase.include?(dupstr) do
    newbase.gsub!(dupre, replacementchar)
  end
  if newbase.empty? then
    raise ArgumentError, sprintf("dotifying %p (of %p) resulted in an empty string!", base, path)
  end
  return File.join(dir, newbase)
end

class Prog
  def initialize(opts)
    @opts = opts
    @force = opts.force
    @repchar = opts.repchar
    @recursive = opts.recursive
    @pretend = opts.test
    @verbose = opts.verbose
  end

  def msg(fmt, *a, **kw)
    if @verbose then
      str = sprintf(fmt, *a, **kw)
      $stderr.printf("%s", str)
    end
  end

  def ren(path)
    if isdotp(path) then
      return path
    end
    msg("renaming %p ", path)
    newpath = path
    begin
      newpath = dotify(path, @repchar)
      if File.exist?(newpath) then
        if File.stat(path) == File.stat(newpath) then
          #raise Errno::EEXIST, sprintf("destination and source are the same")
          msg("- nothing to do")
          return path
        end
      end
      msg("to %p ... ", newpath)
      if not @pretend then
        if File.exist?(newpath) then
          if not @force then
            raise Errno::EEXIST, sprintf("use -f to override")
          end
        end
        File.rename(path, newpath)
      end
    rescue => ex
      msg("failed: (%s) %s", ex.class.name, ex.message)
      return nil
    else
      msg("done")
    ensure
      msg("\n")
    end
    if @pretend then
      return path
    end
    return newpath
  end

  def descend(tmp)
    Find.find(tmp) do |item|
      ren(item)
    end
  end

  def main(path)
    if File.directory?(path) then
      if (tmp=ren(path)) != nil then
        if @recursive then
          #fail("not yet implemented")
          descend(tmp)
        end
      end
    elsif File.file?(path) then
      ren(path)
    end
  end
end

begin
  opts = OpenStruct.new({
    verbose: false,
    test: false,
    recursive: false,
    force: false,
    repchar: ".",
  })
  (prs=OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-t", "--test", "test only; will not rename anything"){
      opts.test = true
    }
    prs.on("-c<s>", "--char=<s>", "use <s> instead of '.'"){|v|
      opts.repchar = v
    }
    prs.on("-f", "--force", "force overwriting of existing files"){
      opts.force = true
    } 
    prs.on("-v", "--verbose", "enable verbose messages"){
      opts.verbose = true
    }
    prs.on("-r", "--recursive", "rename recursively"){
      opts.recursive = true
    }
  }).parse!
  pr = Prog.new(opts)
  if ARGV.empty? then
    fail("insufficient arguments - try '--help'")
  end
  ARGV.each do |arg|
    pr.main(arg)
  end
end



