#!/usr/bin/ruby

require "optparse"
require "find"
require "fileutils"

MAX_LEVELS = 800
#NEWNAME_TEMPLATE = "%<stem>s (%<index>d)%<ext>s"
NEWNAME_TEMPLATE = "%<srcdir>s.%<stem>s.%<index>d%<ext>s"

def procitem(name, recv, *args, &b)
  b.call
  begin
    recv.call(*args)
  rescue => ex
    $stderr.printf("failed: (%s) %s", ex.class.name, ex.message)
    if ex.class.name.match?(/^Errno::/) then
      return true
    end
    return false
  else
    $stderr.print("ok")
  ensure
    $stderr.print("\n")
  end
  return true
end

def delfile(srcdir, file)
  procitem("delitem", File.method(:delete), file){
    $stderr.printf("in %p: deleting %p ... ", file, srcdir)
  }
end

def deldir(srcdir, dir)
  procitem("deldir", Dir.method(:rmdir), dir){
    $stderr.printf("in %p: removing directory %p ... ", srcdir, dir)
  }
end

def mvfile(srcdir, ffrom, fto)
  procitem("mvfile", File.method(:rename), ffrom, fto){
    $stderr.printf("in %p: renaming %p to %p ... ", srcdir, ffrom, fto)
  }
end

def is_single(dir)
  files = Dir.entries(dir).reject{|s| s.match(/^\.\.?$/) }
  if files.size == 1 then
    return File.join(dir, files.first)
  end
  return nil
end

def make_newname(srcdir, item)
  ci = 0
  dn = File.basename(srcdir).gsub(/\.*/, "").strip
  dir = File.dirname(item)
  base = File.basename(item)
  ext = File.extname(base)
  stem = File.basename(base, ext)
  Dir.chdir(dir) do
    while ci != MAX_LEVELS do
      #nbase = "#{stem}#{ci+1}#{ext}"
      nbase = sprintf(NEWNAME_TEMPLATE, srcdir: dn, stem: stem, index: ci+1, ext: ext)
      if not File.exist?(nbase) then
        return nbase
      end
      ci += 1
    end
  end
  $stderr.printf("make_newname: %p: too many levels (max is %d). giving up\n", item, MAX_LEVELS)
  exit(1)
end

def moveto(srcdir, basename, item, dest)
  destp = File.join(dest, basename)
  if File.exist?(destp) then
    if File.directory?(destp) then
      return system("mvmerge", "-f", item, dest)
    else
      newname = make_newname(srcdir, destp)
      $stderr.printf("warning: a file named %p already exists! file will be renamed to %p\n", basename, newname)
      dest = File.join(dest, newname)
    end
  end
  # don't add an else-branch here: it's supposed to fall through
  if File.directory?(dest) then
    return mvfile(srcdir, item, File.join(dest, basename))
  end
  return mvfile(srcdir, item, dest)
end

def handle(dir)
  ci = 0
  if File.stat(dir) == File.stat(__dir__) then
    $stderr.printf("cannot use mvsingle in the same directory as mvsingle!\n")
  else
    Dir.chdir(dir) do
      Dir.glob("*") do |path|
        next unless File.directory?(path)
        if (sfile=is_single(path)) != nil then
          sfbase = File.basename(sfile)
          if (sfbase.downcase == File.basename(path).downcase) then
            npath = "#{path}.#{Time.now.tv_nsec}"
            mvfile(dir, path, npath)
            path = npath
            sfile = File.join(path, sfbase)
          end
          if moveto(dir, sfbase, sfile, ".") then
            if Dir.empty?(path) then
              deldir(dir, path)
            end
          end
          ci += 1
        end
      end
    end
  end
  return ci
end

class Deep
  def initialize
    @counter = 0
  end

  def deep(dir)
    Find.find(dir) do |path|
      next unless File.directory?(path)
      #$stderr.printf("\n++++ entering %p ++++\n", path)
      @counter += handle(path)
    end
  end

  def status
    $stderr.printf("moved %d items\n", @counter)
    if (@counter > 0) then
      exit(true)
    end
    exit(false)
  end
end

begin
  $stdout.sync = true
  dodeep = false
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(true)
    }
    prs.on("--deep", "run mvsingle on every subdirectory"){
      dodeep = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.puts("missing directory name[s]")
    exit(false)
  else
    if dodeep then
      d = Deep.new
      begin
        ARGV.each do |arg|
          d.deep(arg)
        end
      ensure
        d.status
      end
    else
      ARGV.each do |arg|
        handle(arg)
      end
    end
  end
end


