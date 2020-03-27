#!/usr/bin/ruby

require "uri"
require "optparse"

def getresponse(word, opts)
  ci = 0
  w = URI.encode(word)
  url = sprintf("https://www.startpage.com/cgi-bin/csuggest?output=json&pl=ff&lang=%<lang>s&query=%<word>s", word: w, **opts)
  return IO.popen(["curl", "-s", url]) do |io|
    io.read.strip
  end
end

def getsuggestion(word, opts)
  body = getresponse(word, opts)
  if body.empty? then
    $stderr.printf("note: no suggestions available for %p\n", word)
  else
    body.each_line do |line|
      line.strip!
      next if line.empty?
      puts(line)
    end
  end
end

begin
  # this doesn't seem to actually make any difference...?
  opts = {
    lang: "english", 
  }
  OptionParser.new{|prs|
    prs.on("-l<lang>", "--language=<lang>"){|v|
      opts[:lang] = v
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("usage: spsuggest <word> [<another-word> ...]\n")
    exit(1)
  else
    ARGV.each do |arg|
      getsuggestion(arg, opts)
    end
  end
end
