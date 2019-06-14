#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "pp"
require "json"

# 7z -ba -slt <archive>

def fail(fmt, *a, **kw)
  str = (if (a.empty? && kw.empty?) then fmt else sprintf(fmt, *a, **kw) end)
  $stderr.printf("ERROR: %s\n", str)
  exit(1)
end

def fmtfilesize(size)
  units = ['B', 'K', 'M', 'G', 'T', 'P', 'E']
  if size == 0 then
    return '0B'
  end
  exp = (Math.log(size) / Math.log(1024)).to_i
  if exp > 6 then
    exp = 6
  end
  return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
end

class Item
  attr_reader :data

  def initialize(data)
    @data = data
    @attribs = (
      if @data.key?("attributes") then
        @data["attributes"].chars
      else
        []
      end
    )
    @isdir = _isdir
    @isfile = _isfile
    @path = @data["path"]
    @size = @data["size"].to_i
    if file? then
      @fmtsize = fmtfilesize(@size)
    end
  end

  def _isfile
    return ((not @attribs.include?("D")) && (@data["folder"] == "-"))
  end

  def _isdir
    return ((@attribs.include?("D")) && (@data["folder"] == "+"))
  end

  def [](key)
    return @data[key]
  end

  def path
    return @path
  end

  def directory?
    return @isdir
  end

  def file?
    return @isfile
  end

  def size
    return @size
  end

  def fmtsize
    if file? then
      return @fmtsize
    end
    return "-"
  end

  def to_json
    return JSON.pretty_generate(@data)
  end
end

def complain(premsg, ex, line, vals, chunk, data)
  $stderr.printf("parse failed:")
  if premsg then
    $stderr.printf("%s:", premsg)
  end
  if ex then
    $stderr.printf("(%s) %s", ex.class.name, ex.message)
  end
  $stderr.printf("\n")
  $stderr.printf("line: %p\n", line) if line
  $stderr.printf("vals: %p\n", vals) if vals
  $stderr.printf("in chunk: [[\n%s\n]]\n", chunk.lines.map{|s| sprintf("  > %p", s.strip) }.join("\n"))
  if data then
    $stderr.printf("data so far:\n")
    data.each do |k, v|
      $stderr.printf("  data[%p] = %p\n", k, v)
    end
  end
  $stderr.printf("---[ end of error ]---\n")
end

def parse(chunk)
  data = {}
  chunk.split(/\n/).map(&:strip).reject(&:empty?).each do |line|
    vals = line.split("=")
    keyname = vals[0]
    rest = vals[1 .. -1]
    begin
      keyname = keyname.strip.gsub(/\s/, "").downcase
      val = rest.join("=").strip
      if ((not val.empty?)) then
        if (keyname == "alternatestreams") && (val == "-") then
          next
        end
        data[keyname] = val
      end
    rescue => ex
      complain(nil, ex, line, vals, chunk, data)
      exit
    end
  end
  #if not data["attributes"] then
    #complain("'attributes' field missing", nil, nil, nil, chunk, data)
    #data["attributes"] = ""
  #end
  return Item.new(data)
end

def do7zlist(file, opts, &b)
  IO.popen([opts.exe, "l", "-ba", "-slt", file]) do |iofh|
    iofh.read.gsub(/\0/, "").scrub.split(/\n\n/).each do |chunk|
      b.call(parse(chunk))
    end
  end
end

def outformat(item, ofile, opts)
  ofile.printf("%s\t%s\n", item.fmtsize, item.path)
end

def filemain(file, opts)
  cache = []
  filehnd = nil
  if opts.outfile then
    filehnd = File.open(opts.outfile, "wb")
  end
  ofile = (filehnd || $stdout)
  begin
    do7zlist(file, opts) do |item|
      next if (item.file? && opts.excludefiles)
      next if (item.directory? && opts.excludedirs)
      if opts.json then
        cache.push(item.data)
      else
        outformat(item, ofile, opts)
      end
    end
  ensure
    if opts.json then
      ofile.write(JSON.pretty_generate(cache))
    end
    if filehnd != nil then
      filehnd.close
    end
  end
end

begin
  opts = OpenStruct.new({
    exe: "7z",
    json: false,
    excludedirs: false,
    excludefiles: false,
    outfile: nil,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help"){|_|
      puts(prs.help)
      exit(0)
    }
    prs.on("-e<exe>", "--exe=<exe>", "specify a different 7z exe (default is '7z')"){|v|
      opts.exe = v
    }
    prs.on("-f", "--files", "print files only"){|_|
      opts.excludedirs = true
    }
    prs.on("-d", "--dirs", "print dirs only"){|_|
      opts.excludefiles = true
    }
    prs.on("-j", "--json", "output as JSON"){|_|
      opts.json = true
    }
    prs.on("-o<file>", "--output=<file>"){|v|
      opts.outfile = v
    }
  }.parse!
  if ARGV.empty? then
    fail("need at least one filename")
  else
    if (opts.excludedirs && opts.excludefiles) then
      # uhh...
    end
    #file = ARGV.shift
    #filemain(file, opts)
    ARGV.each do |file|
      filemain(file, opts)
    end
  end
end

