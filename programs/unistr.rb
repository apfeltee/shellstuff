#!/usr/bin/ruby

####
## print input data as unicode escapes.
## i.e., 
##
##  $ unistr <<<'foo'
##  \u66\u6f\u6f\ua
##  $ printf "\u66\u6f\u6f\ua"
##  foo
##
## NB. does not write a final newline (works best with zsh), but
## this shouldn't be a problem for any shell, really.
## meant for binary data, really.
####

require "ostruct"
require "optparse"

def printunistr(byte, rubystyle)
  hex = byte.to_s(16)
  unstr = (
    if rubystyle then
      sprintf('\u{%s}', hex)
    else
      sprintf('\u%s', hex)
    end
  )
  $stdout.write(unstr)
  $stdout.flush
end

def printunihandle(hnd, opts)
  rs = opts.rubystyle
  skim = opts.skim
  hnd.each_byte do |b|
    if ((b == 10) && hnd.eof?) && skim then
      return
    end
    printunistr(b, rs)
  end
end

def printunifile(file, opts)
  begin
    File.open(file, "rb") do |fh|
      printunihandle(fh, opts)
    end
  rescue => ex
    $stderr.printf("unistr: failed to open %p: (%s) %s\n", )
    return false
  end
  return true
end

begin
  opts = OpenStruct.new({
    rubystyle: false,
    skim: false,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "print this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-s", "--strip", "--skim", "ignore last linefeed character from input"){
      opts.skim = true
    }
    prs.on("-r", "--rubystyle", "print ruby-style unicode escapes (\\u{...})"){
      opts.rubystyle = true
    }
  }.parse!
  begin
    rc = 0
    if ARGV.empty? then
      printunihandle($stdin, opts)
    else
      ARGV.each do |arg|
        rc += (printunifile(arg, opts) ? 0 : 1)
      end
    end
    exit(rc == 0 ? 0 : 1)
  rescue Interrupt
    exit(0)
  end
end
