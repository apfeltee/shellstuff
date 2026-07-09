#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "stringio"


def is_wsl
  if (ENV["WSL_DISTRO_NAME"]) || (ENV["WTSESSION"]) || File.directory?("/mnt/c/") then
    if File.file?("/proc/version") then
      ver = File.read("/proc/version")
      if ver.match?(/microsoft/i)  then
        return true
      end
    end
  end
  return false
end

class Clipboard
  MINCHUNKSIZE = (1024 * 32)

  def initialize(options)
    @devclipboard = "/dev/clipboard"
    @options = options
    @clipexe = nil
    @iswsl = is_wsl()
    if @iswsl then
      @clipexe = "/mnt/c/windows/system32/clip.exe"
    end
  end

  def verbose(fmt, *args)
    if @options.verbose then
      $stderr.printf("- %s\n", sprintf(fmt, *args))
    end
  end

  def doecho(fmt, *args)
    if @options.echo then
      $stderr.printf("- %s\n", sprintf(fmt, *args))
    end
  end

  def log(fmt, *args)
    $stderr.printf("+ %s\n", sprintf(fmt, *args))
  end

  def print_contents
    if @clipexe then
      $stderr.printf("**error: not supported. sorry**")
    else
      $stdout.puts(File.read(@devclipboard))
    end
  end

  def write_chunk(fromfh, tofh, chunk)
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

  def write_contents_devcb(inhandle)
    writtenbytes = 0
    File.open(@devclipboard, "wb") do |fh|
      #inhandle.each_line do |chunk|
      while true do
        chunk = inhandle.read(MINCHUNKSIZE)
        if chunk == nil then
          break
        end
        chunksz = write_chunk(inhandle, fh, chunk)
        writtenbytes += chunksz
        verbose("[%-05db]: %p", chunksz, chunk)
      end
    end
    log("wrote %d bytes in total", writtenbytes)
  end

  def write_contents_clipexe(inhandle)
    data = inhandle.read
    IO.popen([@clipexe], "wb") do |io|
      doecho("[%-05db]: %p", data.bytesize, data)
      io.write(data)
    end
    $stderr.printf("wrote %d bytes\n", data.bytesize)
  end

  def write_contents(inhandle=$stdin)
    if @clipexe != nil then
      write_contents_clipexe(inhandle)
    else
      write_contents_devcb(inhandle)
    end
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
    echo: true,
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

