#!/usr/bin/ruby

require "ostruct"
require "optparse"

RENAME_TEMPLATE = "%{stem}.%{count}%{ext}"

def msg(verbose, fmt, *a)
  if verbose then
    $stderr.printf("-- %s\n", sprintf(fmt, *a))
  end
end

def ren(opts, file, dest)
  msg(opts.verbose, "ren %p -> %p", file, dest)
  if opts.testdrive then
    return
  end
  begin
    File.rename(file, dest)
  rescue => ex
    $stderr.printf("error: rename(%p, %p) failed: (%s) %s\n", file, dest, ex.class.name, ex.message)
    return false
  end
  return true
end

def isnoe(s)
  return ((s == "") || (s == nil))
end

def mknew(opts, file)
  cnt = 1
  dir = File.dirname(file)
  base = File.basename(file)
  ext = File.extname(base)
  stem = File.basename(base, ext)
  if isnoe(dir) || isnoe(base) || isnoe(stem) then
    $stderr.printf("something about %p is wrong...\n", file)
    exit(1)
    return nil
  end
  while true do
    npath = File.join(dir, sprintf(opts.template, stem: stem, count: cnt, ext: ext))
    if not File.exist?(npath) then
      return npath
    end
    cnt += 1
  end
end

def mmv(opts, path, destpath)
  if File.exist?(destpath) then
    msg(opts.verbose, "file %p already exists, selcting new name...", destpath)
    destpath = mknew(opts, destpath)
    msg(opts.verbose, "new filename: %p", destpath)
  end
  return ren(opts, path, destpath)
end

begin
  ec = 0
  opts = OpenStruct.new({
    template: RENAME_TEMPLATE,
    verbose: false,
    testdrive: false,
  })
  OptionParser.new{|prs|
    prs.on("-t<s>", "--template=<s>", "set renaming template (default: #{RENAME_TEMPLATE.dump})"){|v|
      opts.template = v
    }
    prs.on("-v", "--verbose", "show what's being done"){
      opts.verbose = true
    }
    prs.on("-t", "--test", "don't actually rename anything"){
      opts.testdrive = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("error: too few arguments\n")
    exit(1)
  else
    paths = ARGV[0 .. -2]
    dest = ARGV[-1]
    if paths.length > 1 then
      if not File.directory?(dest) then
        $stderr.printf("error: with more than >1 file, last argument must be a directory\n")
        exit(1)
      end
      paths.each do |path|
        dpath = File.join(dest, dest)
        ec += mmv(opts, path, dpath) ? 0 : 1
      end
    else
      ec += mmv(opts, paths[0], dest) ? 0 : 1
    end
  end
  exit(ec > 0 ? 1 : ec)
end

