#!/usr/bin/ruby

require "ostruct"
require "optparse"

=begin
pub/Linux:
total 110
lrwxrwxrwx   1 root     guru           8 Feb 25 00:55 00Directory_info.txt -> .message
drwxrwx--x   5 arl      linux-adm       6 Aug 11  1999 ALPHA
-rw-r-----   1 arl      ftp          236 Nov  1  1992 ALPHA.ind
drwxrwxr-t  21 arl      ftp           53 Aug 11  1999 BETA
-rw-rw----   1 arl      ftp          173 Nov  1  1992 BETA.ind
lrwxrwxrwx   1 root     csc            6 Feb 25 00:55 INSTALL -> images
drwxrwxr-t   5 arl      ftp           10 Dec 18  2003 PEOPLE
drwx------  10 arl      ftp           11 Mar  7  2007 YLLAPITO
drwxr-xr-x  11 mirror   linux-adm      13 Aug 11  1999 atm
lrwxrwxrwx   1 root     csc           11 Feb 25 00:55 axp -> mirrors/axp
drwxrwsr-t   4 ruokonen linux-adm     156 Aug 11  1999 bin
=end

def size_to_readable(size)
  # byte, kilobyte, megabyte, gigabyte, terabyte, petabyte, exabyte, zettabyte
  # the last two seem... unlikely, tbh
  units = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']
  if (size == 0) then
    return '0B'
  end
  exp = (Math.log(size) / Math.log(1024)).to_i
  if (exp > 6) then
    exp = 6
  end
  return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
end

def format_lslr(inputtext, opts)
  raw = inputtext
  fmt = (opts.format_string || "%s")
  raw.split(/\n\n/).each do |chunk|
    chunk.strip!
    next if chunk.empty?
    lines = chunk.split(/\n/).map(&:strip).reject(&:empty?)
    head = lines.shift
    if head[-1] != ":" then
      $stderr.printf("wonky ls-lR format: expected chunk to start with '<path>:', got %p instead\n", head)
      #exit(1)
    end
    head = head[0 .. -2]
    totstr = lines.shift
    lines.each do |line|
      parts = line.split(/\s+/)
      fperms, numhardlinks, ownername, ownergrp, size, tmon, tday, ttime, *path = parts
      next if (parts == [])
      next if (parts[1] == "->")
      if (numhardlinks == nil) || (size == nil) then
        next
      end
      if (not numhardlinks.match?(/^\d+$/)) || (not size.match?(/^\d+$/)) then
        $stderr.printf("wonky ls-lR format!\n")
        next
      end
      tmpath = path.join(" ")
      while tmpath.match?(/^\.\//) do
        tmpath = tmpath[1 .. -1]
      end
      #$stderr.printf("<<tmpath=%p>>\n", tmpath)
      actualpath = File.join(head, tmpath)
      printpath = sprintf(fmt, actualpath).gsub(/\/\.\//, "/")
      hsize = size_to_readable(size.to_i)
      printf("%s\t%s\n", hsize, printpath)
    end
  end
end

begin
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
    prs.on("-f<s>", "--format=<s>"){|v|
      opts.format_string = v
    }
  }.parse!
  if ARGV.empty? then
    format_lslr($stdin.read.scrub, opts)
  else
    ARGV.each do |arg|
      format_lslr(File.read(arg).scrub, opts)
    end
  end
end
