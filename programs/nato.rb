#!/usr/bin/ruby

####
## print input as NATO phonetic alphabet.
## i.e.,
##
##  $ nato <<<foobar
##  $ FOXTROT OSCAR OSCAR BRAVO ALFA/ALPHA ROMEO
##
## todo: reverse translate
###

require "ostruct"
require "optparse"

ALPH = {
  "a" => ["ALPHA", ". -"],
  "b" => ["BRAVO", "- . . ."],
  "c" => ["CHARLIE", "- . - ."],
  "d" => ["DELTA", "- . ."],
  "e" => ["ECHO", ".."],
  "f" => ["FOXTROT", ". . - ."],
  "g" => ["GOLF", "- - ."],
  "h" => ["HOTEL", ". . . ."],
  "i" => ["INDIA", ". ."],
  "j" => ["JULIETT", ". - - -"],
  "k" => ["KILO", "- . -"],
  "l" => ["LIMA", ". - . ."],
  "m" => ["MIKE", "- -"],
  "n" => ["NOVEMBER", "- ."],
  "o" => ["OSCAR", "- - -"],
  "p" => ["PAPA", ". - - ."],
  "q" => ["QUEBEC", "- - . -"],
  "r" => ["ROMEO", ". - ."],
  "s" => ["SIERRA", ". . ."],
  "t" => ["TANGO", "-"],
  "u" => ["UNIFORM", ". . -"],
  "v" => ["VICTOR", ". . . -"],
  "w" => ["WHISKEY", ". - -"],
  "x" => ["XRAY", "- . . -"],
  "y" => ["YANKEE", "- - . ."],
  "z" => ["ZULU", "- - - - -"],
}


def printnatohandle(hnd, opts)
  wantnato = opts.wantnato
  wantdowncase = opts.wantdowncase
  sep = opts.separator
  hnd.each_char do |ch|
    upc = ch.downcase
    if ALPH.include?(upc) then
      outstr = (
        if wantnato then
          ALPH[upc][0]
        else
          ALPH[upc][1]
        end
      )
      if wantdowncase then
        outstr.downcase!
      end
      $stdout.write(outstr)
      if not hnd.eof? then
        $stdout.write(sep)
      end
      $stdout.flush
    end
  end
end

def printnatofile(file, opts)
  begin
    File.open(file, "rb") do |fh|
      printnatohandle(fh, opts)
    end
  rescue => ex
    $stderr.printf("nato: failed to open %p: (%s) %s\n", )
    return false
  end
  return true
end

begin
  opts = OpenStruct.new({
    wantnato: true,
    wantdowncase: false,
    separator: " ",
    
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "print this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-s<str>", "--separator=<str>", "separate words by <str> (default: space)"){|s|
      opts.separator = s
    }
    prs.on("-d", "--lowercase", "--downcase", "print words lowercase"){
      opts.wantdowncase = true
    }
    prs.on("-m", "--morse", "print morse codes equivalents"){
      opts.wantnato = false
    }
  }.parse!
  begin
    rc = 0
    if ARGV.empty? then
      printnatohandle($stdin, opts)
    else
      ARGV.each do |arg|
        rc += (printnatofile(arg, opts) ? 0 : 1)
      end
    end
    exit(rc == 0 ? 0 : 1)
  rescue Interrupt
    exit(0)
  end
end
