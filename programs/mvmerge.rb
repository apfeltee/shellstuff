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

module FileAction
  
end

class MVMergeProgram
  def initialize(opts)
    @opts = opts
    @statself = nil
  end

  # just wraps FileUtils, so the -v flag takes action
  def wrapfutils(sym, *args)
    return FileUtils.send(sym, *args, verbose: @opts.verbose)
    #$stderr.printf("%s(%p)\n", sym, args)
    #return FileUtils.send(sym, *args)
  end

  def futils_mv(src, dest)
    begin
      wrapfutils("mv", src, dest)
    rescue => ex
      $stderr.printf("ERROR: (%s) %s\n", ex.class.name, ex.message)
    end
  end

  def futils_rmrf(path)
    wrapfutils("rm_rf", path)
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
    elsif File.file?(srcdest) then
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
    elsif File.directory?(srcdest) then
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
      if File.directory?(src) then
        if mergedirs(src, dest) then
          futils_rmrf(src)
        else
          error("copy+merge of %p to %p failed?", src, dest)
          rc = 1
        end
      elsif File.file?(src) then
        futils_mv(src, dest)
      else
        error("%p is neither a regular file, nor a directory", src)
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

