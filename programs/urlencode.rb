#!/usr/bin/ruby --disable-gems

require "uri"
require "cgi"
require "ostruct"
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

def escape(s)
  return CGI.escape(s)
end

def iter(opts,input, output)
  while true do
    chunk = input.read(1024)
    if chunk == nil then
      return
    end
    if opts.stripallws then
      chunk.strip!
    else
      if opts.stripleftws then
        chunk.lstrip!
      elsif opts.striprightws then
        chunk.rstrip!
      end
    end
    esc = escape(chunk)
    begin
      output.write(esc)
    rescue Errno::EPIPE
    end
  end
end

begin
  inp = $stdin
  outp = $stdout
  opts = OpenStruct.new({
    stripallws: false,
    stripleftws: false,
    striprightws: false,
  })
  OptionParser.new{|prs|
    prs.on("-s", "--strip", "strip whitespace (left and right)"){
      opts.stripallws = true
    }
    prs.on("--rstrip", "strip whitespace from the beginning of each chunk"){
      opts.striprightws = true
    }
    prs.on("--lstrip", "strip whitespace from the end of each chunk"){
      opts.stripleftws = true
    }
  }.parse!
  if (opts.stripleftws && opts.striprightws) then
    opts.stripallws = true
    opts.stripleftws = false
    opts.striprightws = false
  end
  first = ARGV.first
  if first then
    ARGV.each do |arg|
      if File.file?(arg) then
        File.open(arg, "rb") do |fh|
          iter(opts, fh, outp)
        end
      else
        iter(opts, StringIO.new(arg), outp)
      end
    end
  else
    iter(opts, inp, outp)
  end
end

