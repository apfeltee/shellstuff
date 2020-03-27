#!/usr/bin/ruby

require "tempfile"
require "optparse"

BADCHARS = [
  # nul bytes seem to appear in really old files
  0,
  1,
  2,
  3,
  4,
  "\32".ord,
  "\f".ord,
  "\7".ord,
  4,
  138,
  255,
]

def owrite(fhdest, thing)
  if thing.is_a?(Numeric) then
    fhdest.putc(thing)
  else
    fhdest.write(thing)
  end
end

def fixsource(path, v=false)
  mustrename = false
  didfinish = false
  hadfailed = false
  fixcnt = 0
  tmpfile = Tempfile.new(File.basename(path))
  $stderr.printf("fixing %p ... ", path)
  begin
    File.open(path, "rb") do |fh|
      fh.each_byte do |ch|
        if BADCHARS.include?(ch) then
          mustrename = true
          fixcnt += 1
          next
        end
        owrite(tmpfile, ch)
      end
    end
    didfinish = true
  rescue => ex
    $stderr.printf("error: %p: (%s) %s\n", path, ex.class.name, ex.message)
    hadfailed = true
  ensure
    tmpfile.close
    begin
      if (mustrename == true) then
        if (didfinish == false) then
          $stderr.printf("did not finish, cannot rename. file remains as-is") if v
        else
          $stderr.printf("did %d corrections, renaming ... ", fixcnt) if v
          begin
            # nb. don't use rename, because this will mess up file permissions
            # on cygwin
            #File.rename(tmpfile.path, path)
            File.open(path, "wb") do |ofh|
              File.open(tmpfile.path, "rb") do |ifh|
                ofh.write(ifh.read)
              end
            end
          rescue => ex
            if v then
              $stderr.printf("failed: (%s) %s", ex.class.name, ex.message)
            else
              $stderr.printf("failed: %p: (%s) %s\n", path, ex.class.name, ex.message)
            end
            hadfailed = true
          else
            $stderr.printf("done!") if v
          end
        end
      else
        $stderr.printf("no fixing necessary")
      end
    ensure
      $stderr.printf("\n")
    end
    tmpfile.unlink
  end
  return hadfailed
end

begin
  subs = {}
  verbose = false
  OptionParser.new{|prs|
    prs.on("-g<find=replace>", "replace each <find> with <replace> - <find> may be a regex"){|v|
      parts = v.split("=")
    }
    prs.on("-v", "--verbose", "enable verbose messages"){
      verbose = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("usage: fixsrc [<options>] <file> ...\n")
    exit(1)
  else
    errc = 0
    ARGV.each do |arg|
      errc += (if not fixsource(arg, verbose) then 1 else 0 end)
    end
  end
  exit(errc > 0 ? 1 : 0)
end
