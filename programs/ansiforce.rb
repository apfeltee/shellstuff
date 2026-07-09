#!/usr/bin/ruby

require "ostruct"
require "optparse"

TARGETENCODING = Encoding::ASCII

def exfmt(ex, *fmt)
  $stderr.printf("ERROR (%s): ", ex.class.name)
  $stderr.printf(*fmt)
  $stderr.printf(" (%s)\n", ex.message)
end

def byte2char(b, otherwise)
  begin
    return b.chr
  rescue
  end
  return otherwise
end

class ANSIForce
  def initialize(file)
    @file = file
    @data = nil
  end

  def readdata()
    begin
      @data = File.read(@file)
      begin
        @data.scrub!
        return true
      rescue => ex
        exfmt(ex, "failed to scrub data")
      end
    rescue => ex
      exfmt(ex, "failed to read from %p", @file)
    end
    return false
  end

  def converttoansi()
    enc = TARGETENCODING
    begin
      #@data = @data.force_encoding(enc)
      #@data = @data.unpack("U*").map{ |c| byte2char(c, '?') }.join
      @data.encode!(enc, invalid: :replace, undef: :replace, replace: "?")
      return true
    rescue => ex
      exfmt(ex, "failed to convert %p to encoding %p", @file, enc)
    end
    return false
  end

  def writebacktofile()
    begin
      File.open(@file, "wb", external_encoding: TARGETENCODING) do |ofh|
        ofh.write(@data)
        ofh.flush
      end
      return true
    rescue => ex
      exfmt(ex, "failed to write data (%d bytes) back to %p", @data.bytesize, @file)
    end
    return false
  end

  def run()
    if readdata() then
      if converttoansi() then
        return writebacktofile()
      end
    end
    return false
  end
end

def doit(file)
  af = ANSIForce.new(file)
  if af.run() then
    $stderr.printf("converted %p!\n", file)
    return true
  end
  return false
end

begin
  ec = 0
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
  
  }.parse!
  if ARGV.length > 0 then
    ARGV.each do |arg|
      if !doit(arg) then
        ec += 1
      end
    end
    exit((ec == 0) ? 0 : 1)
  else
    sf = File.basename($0)
    $stderr.printf("usage: %s <files...>\n")
    exit(1)
  end
end
