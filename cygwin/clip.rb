#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "stringio"

class Clipboard
  CLIPBOARD_PATH = "/dev/clipboard"

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

  def write_contents(inhandle=$stdin)
    writtenbytes = 0
    File.open(CLIPBOARD_PATH, "wb") do |fh|
      inhandle.each_line do |chunk|
        chunk.strip! if @options.strip_input
        if @options.replacenulls then
          chunk.gsub!(/\0/, @options.replacenulls)
        end
        $stderr.printf("%p\n", chunk) if @options.echo
        writtenbytes += fh.syswrite(chunk)
        if (not @options.strip_input) && (chunk[-1] != "\n") then
          writtenbytes += fh.syswrite("\n")
        end
        verbose("chunk of %d bytes", writtenbytes)
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

