#!/usr/bin/ruby

require "ostruct"
require "optparse"


Result = Struct.new(:string, :lineno)

class BaseInfo

  def initialize(opts, file)
    @opts = opts
    @file = file
  end

  def run
  end

  def each(&b)
  end
end

class IncludesInfo < BaseInfo
  REGEX = /^\s*#\s*include\s*(?<quoted>[<"](?<file>.*)[">])/

  def initialize(opts, file)
    super(opts, file)
  end

  def each(&b)
    File.foreach(@file).with_index do |line, i|
      next unless line.include?("include")
      cps = line.scrub
      if (m = cps.match(REGEX)) != nil then
        if @opts.withquotes then
          b.call(Result.new(m["quoted"], i))
        elsif @opts.onlyfiles then
          b.call(Result.new(m["file"], i))
        else
          b.call(Result.new(cps.rstrip, i))
        end
      end
    end
  end
end

class PreprocessorInfo
  REGEX = /^\s*#\s*\b(?<token>\w+)\b\s*(?<args>.*)/

  def initialize(opts, file)
    super(opts, file)
  end

  def each(&b)
    File.foreach(@file)
  end
end

class LineWriter
  def initialize(opts, outfh, filename)
    @opts = opts
    @outfh = outfh
    @filename = filename
    @buffer = []
  end

  def reset
    @buffer = []
  end

  def push(*s)
    @buffer.push(*s)
  end

  def fpush(fmt, *a, **kw)
    @buffer.push(sprintf(fmt, *a, **kw))
  end

  def printout
    if @opts.printfile then
      @outfh.printf("%s: ", @filename)
    end
    @buffer.each do |chunk|
      @outfh.write(chunk)
    end
  end
end

class Program
  KLASSES = {
    "includes" => IncludesInfo,
  }

  def initialize(opts, args)
    @opts = opts
    if KLASSES.key?(@opts.mode) then
      args.each do |file|
        dofile(file)
      end
    else
      $stderr.printf("no such mode implemented yet: %p\n", @opts.mode)
      exit(1)
    end
  end

  def dofile(file)
    cli = KLASSES[@opts.mode].new(@opts.extraopts, file)
    cli.run
    lw = LineWriter.new(@opts, $stdout, file)
    cli.each do |res|
      lw.reset
      if @opts.printlno then
        lw.fpush("%d: ", res.lineno)
      end
      lw.fpush("%s\n", res.string)
      lw.printout
    end
  end

end

begin
  opts = OpenStruct.new({
    mode: nil,
    printlno: true,
    printfile: true,
    extraopts: OpenStruct.new({
    })
  })

  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-f", "--nofile", "do not prepend filename for results"){
      opts.printfile = false
    }
    prs.on("-n", "--noline", "do not prefix each result with the line number"){
      opts.printlno = false
    }
    prs.on("-i[<typ>]", "--includes[=<typ>]", "print #include statements, where <typ> is [l]ine, [f]ile, [q]uotfile (default: line)"){|s|
      opts.mode = "includes"
      if s != nil then
        s.scrub!
        if s.match?(/^f(file)?/i) then
          opts.extraopts.onlyfiles = true
        elsif s.match?(/^q(uot(ed)?file)?/i) then
          opts.extraopts.withquotes = true
        # more evtl?
        end
      end
    }
  }.parse!
  if ARGV.empty? || opts.mode.nil? then
    $stderr.printf("no files provided, and/or no action given.\n")
    $stderr.printf("try %s --help\n", $0)
    exit(1)
  else
    Program.new(opts, ARGV)
  end
end
