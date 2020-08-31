#!/usr/bin/ruby --disable-gems

require "uri"
require "cgi"
require "optparse"

def _unescape(string, encoding="UTF-8")
  str = string.tr('+', ' ').b.gsub(/((?:%[0-9a-fA-F]{2})+)/){|m|
    [m.delete('%')].pack('H*')
  }.force_encoding(encoding)
  if str.valid_encoding? then
    return str
  end
  return str.force_encoding(string.encoding)
end

def urldecode(str)
  
end

def iter(input, output)
  while true do
    chunk = input.read(1024)
    if chunk == nil then
      return
    end
    esc = _unescape(chunk)
    output.write(esc)
  end
end

begin
  inp = $stdin
  outp = $stdout
  OptionParser.new{|prs|
  }.parse!
  iter(inp, outp)
end