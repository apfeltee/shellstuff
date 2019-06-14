#!/usr/bin/ruby

require "optparse"
require "find"

VALIDCHARS = [
  *(32 .. 126)
]

def isascii(str)
  str.each_byte do |bt|
    if not VALIDCHARS.include?(bt) then
      return false
    end
  end
  return true
end

class FindPseudo
  def initialize(startpath, ofdefinitive, ofmaybe, verbose, debug)
    @startpath = startpath
    @ofdefinitive = ofdefinitive
    @ofmaybe = ofmaybe
    @verbose = verbose
    @debug = debug
    @fhmay = nil
    @fhdef = nil
  end

  def boolmsgwrap(boolvar, destio, pretxt, fmt, *a, nl: true, pre: true)
    if boolvar then
      if pre then
        destio.printf(pretxt)
      end
      destio.printf("%s", (a==[]) ? fmt : sprintf(fmt, *a))
      if nl then
        destio.write("\n")
      end
    end
  end

  def verb(fmt, *args, **kw)
    boolmsgwrap(@verbose, $stderr, "v: ", fmt, *args, **kw)
  end

  def debug(fmt, *args, **kw)
    boolmsgwrap(@debug, $stderr, "d: ", fmt, *args, **kw)
  end

  def getfirst(path)
    lines = []
    idx = 0
    maxlines = 2
    debug("processing %p ... ", path, nl: false)
    File.open(path, "rb") do |fh|
      while true do
        begin
          line = fh.readline
          # if this is the case, then it's not a pseudo-symlink anyway
          if line.match(/\n$/) || line.include?("\0") || (not isascii(line)) then
            debug("discarding: contains non-path bytes", pre: false)
            return nil
          end
          lines.push(line)
          if idx == maxlines then
            raise EOFError
          end
        rescue EOFError
          ### return
          if lines.length == 1 then
            verb("ok", pre: false)
            return lines.first
          else
            debug("discarding: contains more than one line", pre: false)
            return nil
          end
        end
        idx += 1
      end
    end
  end

  def issym(path, pseudo)
    if File.exist?(pseudo) then
      return true
    else
      # maybe it's a relative path
      Dir.chdir(File.dirname(path)) do
        return File.exist?(pseudo)
      end
    end
    return false
  end

  def _init
    if @ofdefinitive == "-" then
      @fhdef = $stdout
    else
      @fhdef = File.open(@ofdefinitive, "wb")
    end
    if @ofmaybe == nil then
      @ofmaybe = $stdout
    else
      if (@ofmaybe != "-") then
        @fhmay = File.open(@ofmaybe, "wb")
      else
        $stderr.printf("error: options '-o' and '-m' cannot both have value '-'!\n")
        exit(1)
      end
    end
  end

  def _fini
    @fhdef.close
    if @fhmay != nil then
      if (@fhmay != $stdout)
        @fhmay.close
      end
    end
  end

  def walk
    somethingelse = []
    _init
    begin
      Find.find(@startpath) do |path|
        next unless File.file?(path)
        line = getfirst(path)
        if line != nil then
          pseudo = line.gsub(/\0/, "").gsub(/^\//, "")
          physdir = File.dirname(path)
          physbase = File.basename(path)
          if issym(path, pseudo) then
            verb("found pseudo-symlink: %p (%p)\n", path, pseudo)
            @fhdef.puts(path)
            @fhdef.flush
          else
            verb("potential pseudo-symlink: %p (%p)\n", path, pseudo)
            if @fhmay != nil then
              @fhmay.puts(path)
              @fhmay.flush
            end
          end
        end
      end
    ensure
      _fini
    end
  end
end

def main()
  ofdef = nil
  ofmay = nil
  verbose = false
  debug = false
  OptionParser.new{|prs|
    prs.on("-o<file>", "--output=<file>", "set outputfile for definitive pseudo-links, or '-' for stdout"){|v|
      ofdef = v
    }
    prs.on("-m<file>", "--maybe=<file>", "set outputfile for files that MIGHT be pseudo-links, or '-' to disable"){|v|
      ofmay = v
    }
    prs.on("-n", "--nomaybe", "like doing '-m-', except explicit"){|_|
      ofmay = nil
    }
    prs.on("-v", "--verbose", "enable verbose messages"){|_|
      verbose = true
    }
    prs.on("-d", "--debug", "enable debugging messages"){|_|
      debug = true
    }
  }.parse!
  if ofdef == nil then
    $stderr.printf("error: you must use '-o' to specify a outputfile or '-' for stdout!\n")
    exit(1)
  end
  firstp = (ARGV.shift || ".")
  argv = [firstp, *ARGV]
  argv.each do |path|
    FindPseudo.new(path, ofdef, ofmay, verbose, debug).walk
  end
end

begin
  main
end