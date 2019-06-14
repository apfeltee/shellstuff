#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "stringio"

class Clipboard
  CLIPBOARD_PATH = "/dev/clipboard"
  MINCHUNKSIZE = (1024 * 32)

  def initialize(options)
    @options = options
  end

  def verbose(fmt, *args)
    if @options.verbose then
      $stderr.printf("- %s\n", sprintf(fmt, *args))
    end
  end

  def log(fmt, *args)
    $stderr.printf("+ %s\n", sprintf(fmt, *args))
  end

  def print_contents
    $stdout.puts(File.read(CLIPBOARD_PATH))
  end

  def write_chunk(fromfh, tofh, chunk)
=begin
    chunk.strip! if @options.strip_input
    if @options.replacenulls then
      chunk.gsub!(/\0/, @options.replacenulls)
    end
    $stderr.printf("%p\n", chunk) if @options.echo
    chunksz = fh.syswrite(chunk)
    if (not @options.strip_input) && (chunk[-1] != "\n") then
      chunksz += fh.syswrite("\n")
    end
=end
    rt = 0
    realdata = nil
    if @options.replacenulls then
      # not implemented yet...
    end
    if @options.strip_input then
      
    end

    # check for options that require modifying input
    if (@options.replacenulls || @options.strip_input) then
      realdata = []
      if @options.replacenulls then
        chunk.each_byte do |byte|
          if byte == 0 then
            realdata.push(@options.replacenulls)
          else
            realdata.push(byte.chr)
          end
        end
        chunk = realdata.join
      end
      if @options.strip_input then
        realdata = []
        chunk.each_line do |line|
          line.rstrip!
          if not line.empty? then
            realdata.push(line)
          end
        end
        chunk = realdata.join(if (realdata.length > 1) then "\n" else nil end)
      end
    end
    return tofh.syswrite(chunk)
  end

  def write_contents(inhandle=$stdin)
    writtenbytes = 0
    File.open(CLIPBOARD_PATH, "wb") do |fh|
      #inhandle.each_line do |chunk|
      while true do
        chunk = inhandle.read(MINCHUNKSIZE)
        if chunk == nil then
          break
        end
        chunksz = write_chunk(inhandle, fh, chunk)
        writtenbytes += chunksz
        verbose("chunk of %d bytes", chunksz)
      end
    end
    log("wrote %d bytes in total", writtenbytes)
  end

  def run
    if $stdin.tty? then
      print_contents
    else
      write_contents
    end
  end
end

begin
  $stdout.sync = true
  $stdin.sync = true
  options = OpenStruct.new(
    replacenulls: nil,
    strip_input: false,
    echo: false,
  )
  OptionParser.new {|prs|
    prs.on("-s", "--[no-]strip", "strip trailing whitespace (default: true)"){|s|
      options.strip_input = s
    }
    prs.on("-e", "--[no-]echo", "print what is being written to clipboard"){|s|
      options.echo = s
    }
    prs.on("-n<replacement>", "--null=<replacement>", "replace nullbytes with <replacement>"){|s|
      options.replacenulls = s
    }
    prs.on("-v", "--verbose", "be verbose"){|_|
      options.verbose = true
    }
  }.parse!
  Clipboard.new(options).run
end

