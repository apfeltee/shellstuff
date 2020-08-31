#!/usr/bin/ruby

# converts "special" URIs, like emoji URIs (i.e., https://i❤.ws/) to punicode.
# handles not just URIs, but strings in general as well.

require "optparse"
require "addressable/uri"
require "simpleidn"

def idnconv(str, wantutf)
  if wantutf then
    return SimpleIDN.to_unicode(str)
  else
    return SimpleIDN.to_ascii(str)
  end
end

def convert(str, wantutf)
  if str.match(/^\w+:\/\//) then
    # parse, extract host, convert host, reassign host
    uri = Addressable::URI.parse(str)
    host = uri.host
    tmp = idnconv(host, wantutf)
    uri.host = tmp
    return uri.to_s
  end
  return idnconv(str, wantutf)
end

begin
  toutf = false
  OptionParser.new{|prs|
    prs.on("-u", "--unicode"){|_|
      toutf = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf(
      "idn converts strings and URIs to punicode\n" +
      "usage: idn [-u] <url/string> ...\n"
    )
    exit(1)
  else
    ARGV.each do |arg|
      $stdout.puts(convert(arg, toutf))
    end
  end
end

