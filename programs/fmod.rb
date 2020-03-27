#!/usr/bin/ruby

require "ostruct"
require "optparse"

def fail(fmt, *a, **kw)
  $stderr.printf("ERROR: %s\n", sprintf(fmt, *a, **kw))
  exit(1)
end


class FileModifyProg
  def initialize(opts)
    @opts = opts
    @total = 0
    @opt_stringsbefore = opts.stringsbefore
    @opt_stringsafter = opts.stringsafter
    @opt_chunksize = opts.chunksize
    @outputhandle = $stdout
    @mustclose = false
    if opts.outputfile != nil then
      @outputhandle = File.open(opts.outputfile, "wb")
      @mustclose = true
    end
    @outputhandle.sync = true
  end

  def finalize
    if @mustclose then
      @outputhandle.close
    end
    $stderr.printf("wrote total of %d bytes\n", @total)
  end

  def owrite(str)
    @total += @outputhandle.write(str)
  end

  def oprintf(fmt, *a, **kw)
    owrite(sprintf(fmt, *a, **kw))
  end

  def oputs(str)
    owrite(str)
    if str[-1] != "\n" then
      owrite("\n")
    end
  end

  def process_handle(io)
    @opt_stringsbefore.each do |str|
      oputs(str)
    end
    while true do
      chunk = io.read(@opt_chunksize)
      if chunk == nil then
        break
      else
        owrite(chunk)
      end
    end
    @opt_stringsafter.each do |str|
      oputs(str)
    end
  end
end

def main(opts, argv)
  if ARGV.empty? && (opts.wantstdin == false) then
    fail("no files specified! use '-i' to read from stdin")
  else
    fmod = FileModifyProg.new(opts)
    begin
      if opts.wantstdin then
        fmod.process_handle($stdin)
      end
      if (opts.outputfile != nil) && (ARGV.length > 1) then
        fail("'-o' can only be used with one file")
      end
      ARGV.each do |arg|
        File.open(arg, "rb") do |infh|
          fmod.process_handle(infh)
        end
      end
    ensure
      fmod.finalize
    end
  end
end

begin
  opts = OpenStruct.new({
    stringsbefore: [],
    stringsafter: [],
    outputfile: nil,
    chunksize: (1024 * 8),
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-o<file>", "--output=<file>", "set output file"){|v|
      opts.outputfile = v
    }
    prs.on("-c<sz>", "--blocksize=<sz>", "--chunksize=<sz>", "set chunksize to <sz> (default: #{1024 * 8})"){|v|
      opts.chunksize = v.to_i
    }
    prs.on("-b<str>", "--before=<str>", "add a string to be written before the file (may be called multiple times)"){|str|
      opts.stringsbefore.push(str)
    }
    prs.on("-a<str>", "--after=<str>", "add a string to be written after the file (may be called multiple times)"){|str|
      opts.stringsafter.push(str)
    }
  }.parse!
  main(opts, ARGV)
end



