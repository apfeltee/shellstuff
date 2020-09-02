#!/usr/bin/ruby -wv

require "ostruct"
require "optparse"
require "find"
require "mimemagic"
require "mimemagic/overlay"
# gem ruby-magic
#require "magic"

#$SAFE = 1
KNOWN_EXTENSIONS = <<__EOF__


image/jpeg : .jpg
image/png : .png
image/x-ms-bmp : .bmp
image/x-icon : .ico
image/x-tga : .tga
image/webp : .webp

application/x-gzip : .gz
application/x-bzip2 : .bz2
application/x-shockwave-flash : .swf
application/x-dosexec : .exe

application/zip : .zip
application/msword : .doc
application/x-executable : .bin

application/x-tar : .tar
application/x-rar : .rar
application/java-archive : .jar

application/vnd.ms-cab-compressed : .cab

#application/octet-stream: .class
#application/x-java-applet : .applet

application/x-sharedlib : .so

application/vnd.ms-excel : .xlsx
application/vnd.ms-powerpoint : .ppt

text/x-c++ : .cpp
text/x-c: .c
text/x-asm: .asm
text/x-tex: .tex
text/x-perl: .pl
text/x-python : .py
text/x-shellscript : .sh
text/x-msdos-batch : .bat
text/x-algol68: .a68
text/x-Algol68: .a68
text/x-diff: .diff
text/x-pascal: .pas
text/x-makefile: .mk
text/x-ruby: .rb
text/x-java: .java
text/x-fortran: .for
text/x-lisp: .lsp

# other text-like files
text/html : .html
text/plain : .txt
text/xml: .xml



text/x-php : .php



message/rfc822: .eml
message/news: .eml


application/x-dosdriver : .sys

application/x-object : .obj


application/x-iso9660-image : .iso
application/x-arc : .arc
__EOF__

# helper func for SHEBANGS
def mkshebang(*interps)
  return Regexp.new('^\s*#\s*!.*(' + interps.join('|') + ')', 'i')
end


## if these extensions are returned by mime/file, then
## also check regular expressions
SUSPICIOUS_EXTENSIONS = %w(
  .txt
  .a68
  .pas
  .cpp
  .al
)

####
## regular expressions to match source files
####
RX_CFILE   = (/
  ^\s*\#\s*\b(define|include|pragma|if(n?def)|else|elifn?def|endif)\b
/)

# pascal file
RX_PASFILE =  rx = /
  (^\s*\b(program|unit)\b\s*[\w\.]+(\s*\(.*\))?\s*;)|
  (\s*=\s*\brecord\b)
/ix

# html files
RX_HTML = /<\w+\s*\w+\s*=["'].*['"]>/i

# xml files
RX_XML     = /<\?\bxml\b/i



## this mapping is used to check when suspicious extensions are encountered
REGEXES = {

  RX_CFILE   => "text/x-c",
  RX_PASFILE => "text/x-pascal",
  RX_XML     => "text/xml",
}

SHEBANGS = {
  mkshebang("perl") => "text/x-perl",
  mkshebang("ruby") => "text/x-ruby",
  mkshebang("sh", "csh", "zsh", "bash", "ksh") => "text/x-shellscript", 
}


# some extensions are redundant - gem files are tar files, for example
EXTFILTER = {
  "jpe" => "jpg",
  "gem" => "tar",
}


def parse(str)
  h = {}
  str.split(/\n/).each do |chunk|
    chunk.strip!
    next if chunk.empty?
    next if chunk.match?(/^\s*#/)
    mime, ext = chunk.split(/:/)
    mime.strip!
    ext.strip!
    h[mime] = ext
  end
  return h
end


def fail(fmt, *a, **kw)
  $stderr.printf("ERROR: %s\n", sprintf(fmt, *a, **kw))
  exit(1)
end

require "magic"


class RbFile
  def initialize
  end

  def close
  end

  # in some rare cases, #descriptor returns empty values
  # this function checks for that, and filters them appropiately.
  def postgetcheck(val)
    if val.is_a?(Array) then
      if val == [] then
        return nil
      end
      first = val[0]
      if (first == nil) || (first == "") then
        return postgetcheck(val[1])
      end
    else
      if val.is_a?(String) then
        if val.strip == "" then
          return nil
        end
      end
    end
    return val
  end

  def get(flag, fh)
    return MimeMagic.by_magic(fh)
=begin
    oflag = @magic.flags
    begin
      @magic.flags = flag
      return postgetcheck(@magic.descriptor(fh.fileno))
    ensure
      @magic.flags = oflag
    end
=end
  end

  def get_mime(fh)
    #return get(Magic::MIME | Magic::CONTINUE, fh)
    return get(0, fh)
  end

  def get_description(fh)
    return get(Magic::CHECK, fh)
  end
end

class FixExtensions
  attr_reader :leftovers

  Wrapper = Struct.new(
    #string
    :type,
    # array
    :extensions
  )

  def initialize(opts)
    @opts = opts
    @extmap = parse(KNOWN_EXTENSIONS)
    @leftovers = Hash.new{|h, k| h[k]=[]}
    @rbfile = RbFile.new
  end

  def get_mime_via_filecmd(filepath)
    mimetype = IO.popen(["file", "-bi", filepath]){|io|
      io.read.strip
    }.split(";").first.downcase
    return Wrapper.new(mimetype, [])
  end

  def get_mime_via_rubymagic(filepath)
    File.open(filepath, "rb") do |fh|
      mime = @rbfile.get_mime(fh)
      $stderr.printf("get_mime=%p\n", mime)
      if (mime == nil) || (mime == []) then
        return Wrapper.new(nil, [])
      end
      #$stderr.printf("rubymagic: mime=%p\n", mime)
      realmime = (
        if mime.is_a?(Array) then
          mime.first
        else
          mime
        end
      ).split(";")[0].strip
      return Wrapper.new(realmime, [])
    end
  end

  def get_mime_via_mimetype(filepath)
    File.open(filepath, "rb") do |ofh|
      rt = MimeMagic.by_magic(ofh)
      if (rt == nil) || (rt == "") || (rt == []) then
        return nil
      end
      return rt
    end
  end

  def get_mime(filepath, hasext)
    begin
      mi = get_mime_via_mimetype(filepath)
      if mi == nil then
        if hasext && (@opts.force == false) then
          # if mimemagic failed, but file already has an extension, then
          # return dummy data, to keep old extension
          return Wrapper.new(nil, [])
        else
          #$stderr.printf("-- get_mime_via_mimetype returned nil for %p\n", filepath)
          #return get_mime_via_filecmd(filepath)
          #return Wrapper.new(nil, [])
          return get_mime_via_rubymagic(filepath)
        end
      end
      return Wrapper.new(mi.type.split(";").first.strip, mi.extensions)
    rescue => ex
      $stderr.printf("get_mime error: (%s) %s\n", ex.class.name, ex.message)
      return Wrapper.new(nil, [])
    end
  end


  def get_ext_by_mime(filepath, oldext)
    hasext = (
      (not @opts.assumenoext) && (
        (oldext != nil) && (
          (oldext != "") &&
          (oldext != ".")
        )
      )
    )
    minfo = get_mime(filepath, hasext)
    mime = minfo.type
    newext = minfo.extensions.first.dup
    if (mime != nil) && ((newext == nil) || @opts.assumenoext) then
      if @extmap.key?(mime) then
        newext = @extmap[mime]
      end
    end
    if (newext != nil) then
      newext.downcase!
      newext = EXTFILTER.fetch(newext, newext)
      if newext[0] != "." then
        newext = ("." + newext)
      end
      if (oldext != newext) then
        return newext
      end
      # return here, otherwise this path would end up in @leftovers
      return nil
    else
      if not @opts.quieterrors then
        $stderr.printf("++ unhandled mimetype: %p (%p)\n", mime, filepath)
      end
      @leftovers[mime].push(filepath)
    end
    return nil
  end

  def get_ext_by_regex(filepath, oldext, oldwasnil)
    if (oldwasnil == false) && ((@opts.assumenoext != true) && (@opts.force != true)) then
      return nil
    end
    ## do shebang check -- shebangs can only be valid if they
    ## appear on the very first line!
    ## the file may also be empty.
    firstline =  File.open(filepath, "rb"){|fh| fh.readline }.scrub rescue ""
    SHEBANGS.each do |rx, mimekey|
      if firstline.match?(rx) then
        $stderr.printf("in get_ext_by_regex: file %p: SHEBANGS: line %p matches %p\n", filepath, firstline, rx)
        return @extmap[mimekey]
      end
    end

    ## waltz through the other regexes
    REGEXES.each do |rx, mimekey|
      File.foreach(filepath) do |ln|
        if ln.scrub.match?(rx) then
          $stderr.printf("in get_ext_by_regex: file %p: REGEXES: line %p matches %p\n", filepath, ln, rx)
          return @extmap[mimekey]
        end
      end
    end
    return nil
  end

  def get_ext(filepath, oldext)
    ext = get_ext_by_mime(filepath, oldext)
    # if get_ext_by_mime returns nil, then try guessing extension via
    # regular expression
    if (ext == nil) || SUSPICIOUS_EXTENSIONS.include?(ext) then
      # get_ext_by_regex will return nil, so double check is needed
      # that is, if get_ext_by_regex returns nil, then keep using ext
      if (nxt = get_ext_by_regex(filepath, oldext, ext == nil)) != nil then
        return nxt
      end
    end
    return ext
  end 

  def process_file(path)
    base = File.basename(path)
    dir = File.dirname(path)
    rawoldext = File.extname(path)
    oldext = rawoldext.strip.downcase
    if not File.file?(path) then
      $stderr.printf("fixext: error: no such file: %p\n", path)
      return
    end
    if (not oldext.empty?) && (@opts.force == false) then
      return
    end
    stem = File.basename(base, rawoldext)
    newext = get_ext(path, oldext)
    #$stderr.printf("newext = %p\n", newext); return
    if newext != nil then
      if (newext == oldext) then
        return
      end
      newbase = (
        if oldext.empty? then
          stem + newext
        elsif (not oldext.empty?) || (@opts.assumenoext == true) then
          stem + newext
        elsif not oldext.empty? then
          if @opts.force then
            stem + newext
          else
            stem + oldext
          end
        end
      )
      newpath = File.join(dir, newbase)
      #$stderr.printf("stem = %p, base = %p, oldext = %p\n", stem, base, oldext)
      $stderr.printf("-- renaming %p to %p ... ", path, newpath)
      begin
        if not @opts.testonly then
          File.rename(path, newpath)
        end
      rescue => ex
        $stderr.printf("failed: (%s) %s", ex.class.name, ex.message)
      else
        $stderr.printf("ok!")
      ensure
        $stderr.printf("\n")
      end
    end
  end
end

def main(opts, items)
  fx = FixExtensions.new(opts)
  items.each do |item|
    if File.directory?(item) then
      if opts.recursive then
        Find.find(item) do |path|
          next unless File.file?(path)
          fx.process_file(path)
        end
      else
        $stderr.printf("fixext: is a directory: %p (specify '-r' to recursively walk directories)\n", item)
      end
    else
      fx.process_file(item)
    end
  end
  if not fx.leftovers.empty? then
    $stderr.printf("\nthere were some unhandled mimetypes:\n")
    fx.leftovers.each do |mime, ufiles|
      if opts.skipunhandledlisting then
        $stderr.printf("  %p (%d files)\n", mime, ufiles.length)
      else
        oflist = (
          if opts.maxfiles == nil then
            ufiles
          else
            maxfiles = ufiles[0 .. opts.maxfiles]
          end
        )
        $stderr.printf("  %p:\n", mime)
        oflist.each do |f|
          $stderr.printf("    %p\n", f)
        end
      end
    end
  end
end

begin
  opts = OpenStruct.new({
    testonly: false,
    assumenoext: false,
    recursive: false,
    force: false,
    skipunhandledlisting: false,
    quieterrors: false,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-t", "--test", "test only; do not actually rename anything"){
      opts.testonly = true
    }
    prs.on("-e", "--noext", "assume input files have no extension at all"){
      opts.assumenoext = true
    }
    prs.on("-r", "--recursive", "walk directory arguments recursively"){
      opts.recursive = true
    }
    prs.on("-f", "--force", "force renaming, even if extension present"){
      opts.force = true
    }
    prs.on("-s", "--nofilelist", "only print short summary for unhandled mime types"){
      opts.skipunhandledlisting = true
    }
    prs.on("-w", "--quieterrors", "disable messages printed for files with unhandled mime types"){
      opts.quieterrors = true
    }
  }.parse!
  files = ARGV
  #p ARGV
  if files.empty? then
    if $stdin.tty? then
      fail("no files specified, and nothing piped! try 'fixext --help'")
    else
      main(opts, $stdin.readlines.map(&:strip).reject(&:empty?))
    end
  else
    main(opts, files)
  end
  $stderr.printf("*done*\n")
end
