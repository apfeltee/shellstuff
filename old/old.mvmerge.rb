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

module FileAction
  
end

class MVMergeProgram
  def initialize(opts)
    @opts = opts
    @statself = nil
    @done = []
  end

  # just wraps FileUtils, so the -v flag takes action
  def wrapfutils(sym, *args)
    #$stderr.printf("%s(%p)\n", sym, args)
    return FileUtils.send(sym, *args, verbose: @opts.verbose)
    #return FileUtils.send(sym, *args)
  end

  def futils_mv(src, dest)
    begin
=begin
      if File.exist?(dest) then
        ci = 1
        while File.exist?(dest) do
          ext = File.extname(dest).gsub(/^\./, "")
          nxt = (if ext.empty? then sprintf("%d", ci) else sprintf("%d.%s", ext, ci) end)
          dest = sprintf("%s.%s", dest, nxt)
          ci += 1
        end
      end
=end
      wrapfutils("mv", src, dest)
    rescue => ex
      $stderr.printf("ERROR: futils_mv: (%s) %s\n", ex.class.name, ex.message)
    end
  end

  # old version just rm -rf'd. this one is slower, but
  # accurately checks whether or not the directories
  # a) are actually directories
  # b) are actually empty
  def futils_rmdir(dir, depthcount=0)
    symcnt = 0
    $stderr.printf("futils_rmdir:%p\n", dir)
    
    if depthcount > 50 then
      $stderr.printf("nesting too deeply. this path seems broken!\n")
      return
    end
    #if we reached this point (see below, leftover check), then
    # there's nothing else to do. not without running into an infinite loop.
    if File.symlink?(dir) then
      return
    end
    if Dir.empty?(dir) then
      wrapfutils("rmdir", dir)
    else
      Dir.entries(dir).each do |itm|
        next if ((itm == ".") || (itm == ".."))
        itm = File.join(dir, itm)
        if File.symlink?(itm) then
          symcnt += 1
        elsif File.directory?(itm) then
          $stderr.printf("rmdir.deep:itm=%p\n", itm)
          if Dir.empty?(itm) then
            wrapfutils("rmdir", itm)
          else
            if not @done.include?(itm.downcase) then
              #@done.push(itm.downcase)
              futils_rmdir(itm, depthcount + 1)
            end
          end
        end
      end
      if symcnt == 0 then
        # check for leftovers
        if Dir.empty?(dir) then
          wrapfutils("rmdir", dir)
        else
          if not @done.include?(dir.downcase) then
            #@done.push(dir.downcase)
            futils_rmdir(dir, depthcount + 1)
            
          end
        end
      end
    end
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
  def mergedirs(src, dest)
    realsrc = File.absolute_path(src)
    realdest = File.absolute_path(dest)
    srcbase = gbasename(src)
    srcdest = File.join(realdest, srcbase)
    if not File.exist?(srcdest) then
      futils_mv(src, srcdest)
    elsif File.file?(srcdest) || File.symlink?(src) then
      # fixme: this is a bogey - but also recursive logic:
      #        will fail (sometimes?) when mergedirs is called recursively.
      if File.stat(srcdest) == @statself then
        error("cannot merge %p with itself\n", srcdest)
      else
        if (@opts.force == true) then
          
          futils_mv(src, dest)
        else
          if @opts.skipexisting == false then
            error("destination %p is a file", srcdest, realsrc)
            return false
          end
        end
      end
    elsif File.directory?(srcdest) && (not File.symlink?(srcdest)) then
      # this where we want to merge!!
      if File.directory?(realsrc) then
        Dir.entries(realsrc).each do |item|
          next if item.match(/^\.\.?$/)
          realitem = File.join(realsrc, item)
          #$stderr.printf("recursive: mergedirs(%p, %p)\n", realitem, srcdest)
          if File.directory?(realitem) then
            realitem = (realitem + "/")
          end
          if not mergedirs(realitem, srcdest) then
            if not @opts.keepgoing then
              return false
            end
          end
        end
      end
    else
      error("destination %p is an unrecognized item (are you sure you know what you're doing?)")
      return false
    end
    return true
  end

  def do_merge(sources, dest)
    rc = 0
    @statself = File.stat(dest)
    sources.each do |src|
      if File.directory?(src) || File.file?(src) then
        if File.file?(src) then
          futils_mv(src, dest)
        else
          if mergedirs(src, dest) then
            if File.directory?(src) then
              futils_rmdir(src)
            end
          else
            error("copy+merge of %p to %p failed?", src, dest)
            rc = 1
          end
        end
      else
        error("%p is neither a regular file, nor a directory", src)
        if src.include?('*') then
          error("maybe the directories are empty?")
        end
        rc = 1
      end
    end
    exit(rc)
  end
end

begin
  opts = OpenStruct.new({
    verbose: false,
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
  end
end

