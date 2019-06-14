#!/usr/bin/ruby

require "tempfile"
require "optparse"

BADCHARS = [
  "\32".ord,
  "\f".ord,
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

def fixsource(path)
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
    $stderr.printf("error: (%s) %s", ex.class.name, ex.message)
    hadfailed = true
  ensure
    tmpfile.close
    begin
      if (mustrename == true) then
        if (didfinish == false) then
          $stderr.printf("did not finish, cannot rename. file remains as-is")
        else
          $stderr.printf("did %d corrections, renaming ... ", fixcnt)
          begin
            File.rename(tmpfile.path, path)
          rescue => ex
            $stderr.printf("failed: (%s) %s", ex.class.name, ex.message)
            hadfailed = true
          else
            $stderr.printf("done!")
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
  OptionParser.new{|prs|
    prs.on("-g<find=replace>", "replace each <find> with <replace> - <find> may be a regex"){|v|
      parts = v.split("=")
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("usage: fixsrc [<options>] <file> ...\n")
    exit(1)
  else
    errc = 0
    ARGV.each do |arg|
      errc += (if not fixsource(arg) then 1 else 0 end)
    end
  end
  exit(errc > 0 ? 1 : 0)
end
