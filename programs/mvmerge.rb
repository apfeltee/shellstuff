#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "fileutils"

class MVMergeProgram
  def initialize(opts)
    @opts = opts
  end

  def futils(sym, *args)
    return FileUtils.send(sym, *args, verbose: @opts.verbose)
  end

  def error(fmt, *args)
    str = (if args.empty? then fmt else sprintf(fmt, *args) end)
    $stderr.printf("error: %s\n", str)
  end

  def gbasename(path)
    return File.basename(path)
  end

  def rsync(src, dest)
    #return system("rsync", "-av", src, dest) 
    realsrc = File.absolute_path(src)
    realdest = File.absolute_path(dest)
    srcbase = gbasename(src)
    srcdest = File.join(realdest, srcbase)
    if not File.exist?(srcdest) then
      futils("mv", src, srcdest)
    elsif File.file?(srcdest) then
      error("destination %p is a file", srcdest)
      return false
    elsif File.directory?(srcdest) then
      # this where we want to merge!!
      Dir.entries(realsrc).each do |item|
        next if item.match(/^\.\.?$/)
        realitem = File.join(realsrc, item)
        if not rsync(realitem, srcdest) then
          return false
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
    sources.each do |src|
      if File.directory?(src) then
        if rsync(src, dest) then
          futils("rm_rf", src)
        else
          error("copy+merge of %p to %p failed?", src, dest)
          rc = 1
        end
      elsif File.file?(src) then
        futils("mv", src, dest)
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
    verbose: true,
  })
  OptionParser.new{|prs|
    prs.on("-v", "--verbose", "show what's being done"){|_|
      opts.verbose = true
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
    if File.directory?(destdir) then
      MVMergeProgram.new(opts).do_merge(sources, destdir)
    else
      $stderr.printf("not a directory: %p\n", destdir)
      exit(1)
    end
  end
end

=begin
exit
DEST="${@:${#@}}"
ABS_DEST="$(cd "$(dirname "$DEST")"; pwd)/$(basename "$DEST")"

for SRC in ${@:1:$((${#@} -1))}; do #(
    cd "$SRC";
    find . -type d -exec mkdir -p "${ABS_DEST}"/\{} \;
    find . -type f -exec mv \{} "${ABS_DEST}"/\{} \;
    find . -type d -empty -delete
#)
done

=end
