#!/usr/bin/ruby --disable-gems

require "optparse"
require "stringio"

class DefaultEncode
  STATIC_REPLACEMENTS = {
    0        => "\\0",
    1        => "\\1",
    "\n".ord => "\\n",
    "\t".ord => "\\t",
    "\r".ord => "\\r",
    "\\".ord => "\\\\",
    '"'.ord  => "\\\"",
  }

  def initialize()
    @default_replacements = STATIC_REPLACEMENTS
  end

  def start
    return '"'
  end

  def finish
    return '"'
  end

  def is_valid(byte)
    return ((byte > 32) && (byte < 127))
  end

  def byte_encode(byte)
    return sprintf("\\x%02X", byte)
  end

  def set_static(byte, replacement)
    @default_replacements[byte] = replacement
  end

  def get_static(byte)
    return @default_replacements[byte]
  end
end

class EncodeRuby < DefaultEncode
  def initialize()
    super()
    set_static('#'.ord, "\\#")
  end
end

class EncodeJS < DefaultEncode
  BAD_CHARS = ["<", ">", "+", "&", "(", ")", "[", "]", "{", "}"]

  def is_valid(byte)
    return (super(byte) && (not BAD_CHARS.include?(byte.chr)))
  end

  def byte_encode(byte)
    return ("\\u" + byte.to_s(16).rjust(4, '0'))
  end
end

def encode(encoder, inio, outio)
  outio.write(encoder.start)
  inio.each_byte do |byte|
    if encoder.is_valid(byte) then
      rep = encoder.get_static(byte)
      if rep.nil? then
        outio.write(byte.chr)
      else
        outio.write(rep)
      end
    else
      outio.write(encoder.byte_encode(byte))
    end
  end
  outio.write(encoder.finish)
end

def from_io(infile, opts)
  enc = opts[:encoder].new
  encode(enc, infile, opts[:outfile])
end

def from_stdin(opts)
  return from_io($stdin, opts)
end

def from_file(filepath, opts)
  File.open(filepath, "rb") do |fh|
    return from_io(fh, opts)
  end
end

begin
  encoders = {
    "default" => EncodeRuby,
    "js"      => EncodeJS,
  }
  opts = {
    outfile: $stdout,
    encoder: encoders["default"],
  }
  prs = OptionParser.new{|prs|
    prs.on("-e<name>", "--encoder=<name>", "select encoder"){|name|
      enc = encoders[name]
      if enc.nil? then
        $stderr.printf("no encoder named %p defined\n", name)
        exit(1)
      end
      opts[:encoder] = enc
    }
  }
  prs.parse!
  if ARGV.empty? then
    if not $stdin.tty? then
      from_stdin(opts)
    else
      $stderr.puts("no files specified, and no input piped")
    end
  else
    ARGV.each do |item|
      from_file(item, opts)
    end
  end
end
