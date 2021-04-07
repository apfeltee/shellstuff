#!/usr/bin/ruby

=begin
  if need be, and this were to be ported to say, C, or C++, then
  you'd need to implement the following:

    futils_mv(a, b)
      moves $a to $b recursively. see also: mv(1)

    futils_rmrf(a)
      ReMoves $a Recursively by Force.
      if $a does not exist, fail successfully (i.e., don't throw an error -
      just acknowledge and move on).
      if $a is a dir, walk $a, and delete the tree (but do not step past $a).
      see also: rm(1), in particular the '-r' and '-f' flags

=end

require "ostruct"
require "optparse"
require "fileutils"
require "find"

class MVMergeProgram
  attr_reader :modified

  def initialize(opts)
    @opts = opts
    @statself = nil
    @done = []
    @modified = 0
  end

  # just wraps FileUtils, so the -v flag takes action
  def wrapfutils(sym, *args)
    #$stderr.printf("wrapfutils(%s, %p)\n", sym, args)
    begin
      rt = FileUtils.send(sym, *args, verbose: @opts.verbose)
      @modified += 1
      return rt
    rescue => ex
      $stderr.printf("ERROR: futils_%s: (%s) %s\n", sym.to_s, ex.class.name, ex.message)
    end
  end

  def futils_mv(src, dest)
    wrapfutils("mv", src, dest)
  end

  def futils_rmdir(dir)
    wrapfutils("rmdir", dir)
  end

  def error(fmt, *args)
    str = (if args.empty? then fmt else sprintf(fmt, *args) end)
    $stderr.printf("error: %s\n", str)
  end

  def gbasename(path)
    return File.basename(path)
  end

  # in theory, this does roughly, sort-of, what `rsync -av <src> <dest>` does.
  # but in a uh, less broken way (don't quote me on that)
  # mergedirs("ms_multiplan_for_xenix/usr", ".")
  def mergedirs_rename(src, dest)
    #$stderr.printf("mergedirs_rename(%p, %p)\n", src, dest)
    basename = File.basename(src)
    odest = File.join(dest, basename)
    if File.exist?(odest) then
      ndest = odest
      ci = 1
      while File.exist?(odest)
        tmp = sprintf("%s.%d", odest, ci)
        ci += 1
        if not File.exist?(tmp) then
          ndest = tmp
          break
        end
      end
      $stderr.printf("destination path %p exists, renaming to %p\n", odest, ndest)
      odest = ndest
    end
    futils_mv(src, odest)
  end

  def mergedirs_children(sourcedir, destdir)
    #$stderr.printf("mergedirs_children(%p, %p)\n", sourcedir, destdir)
    Dir.foreach(sourcedir) do |itm|
      next if %w(. ..).include?(itm)
      fullitm = File.join(sourcedir, itm)
      mergedirs_merge(fullitm, destdir)
    end
    if Dir.empty?(sourcedir) then
      futils_rmdir(sourcedir)
    end
  end

  def mergedirs_merge(src, dest)
    #$stderr.printf("mergedirs_merge(%p, %p)\n", src, dest)
    basename = File.basename(src)
    odest = File.join(dest, basename)
    if File.exist?(odest) then
      if File.symlink?(odest) then
        $stderr.printf("destination path %p is a symbolic link\n", odest)
      elsif File.file?(odest) then
        return mergedirs_rename(src, dest)
      else
        if File.directory?(src) then
          if File.directory?(odest) && (not File.symlink?(odest)) then
            return mergedirs_children(src, odest)
          end
        end
      end
    else
      futils_mv(src, dest)
    end
  end

  def do_merge(sources, dest)
    return if File.symlink?(dest)
    #$stderr.printf("do_merge(%p, %p)\n", sources, dest)
    fulldest = File.absolute_path(dest)
    sources.each do |src|
      fullsrc = File.absolute_path(src)
      next if File.symlink?(fullsrc)
      mergedirs_merge(src, dest)
    end
  end
end

begin
  opts = OpenStruct.new({
    verbose: true,
    keepgoing: false,
    force: false,
    skipexisting: false,
  })
  OptionParser.new{|prs|
    prs.on("-v", "--verbose", "show what's being done"){|_|
      opts.verbose = true
    }
    prs.on("-i", "--ignore-errors", "-k", "--keep-going", "in case of errors, keep going as long as possible"){|_|
      opts.keepgoing = true
    }
    prs.on("-f", "--force", "force merge, including overwriting files"){|_|
      opts.force = true
    }
    prs.on("-s", "--skip", "skip existing files"){|_|
      opts.skipexisting = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("usage: mvmerge <item... > <destination>\n")
    exit(1)
  elsif ARGV.length == 1 then
    $stderr.printf("need more than one argument\n")
    exit(1)
  else
    destdir = ARGV.pop
    sources = ARGV
    mmg = MVMergeProgram.new(opts)
    if (sources.length == 1) && (File.exist?(destdir) == false) then
      # in this case, act like ordinary mv
      mmg.futils_mv(sources[0], destdir)
    else
      if File.directory?(destdir) then
        mmg.do_merge(sources, destdir)
      else
        $stderr.printf("not a directory: %p\n", destdir)
        exit(1)
      end
    end
    exit((mmg.modified > 0) ? 0 : 1)
  end
end

