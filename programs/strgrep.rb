#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "find"

class Pattern
  attr_accessor :pattern

  def self.make_hollerith(str, icase)
    return Pattern.new([str.length, 'H', str].join, false, icase)
  end

  def self.make_basequot(str, asrx, icase)
    if not asrx then  
      str = Regexp.quote(str)
    end
    return Pattern.new(
      ['[\x22\x27]', str, '\s*', '[\x22\x27]'].join, true, icase
    )
  end

  def self.make_quot(str, asrx, icase)
    return Pattern.make_basequot(str, asrx, true)
  end

  # '\x27i\x27.*\x27f\x27'
  def self.make_basesplit(str, chquot, asrx, icase)
    buf = []
    str.each_char do |c|
      buf.push([chquot, c, chquot])
    end
    return Pattern.new(buf.map(&:join).join('.*'), true, icase)
  end

  def self.make_split(str, asrx, icase)
    return Pattern.make_basesplit(str, '\x27', asrx, icase)
  end

  def self.make_qsplit(str, asrx, icase)
    return Pattern.make_basesplit(str, '[\x22\x27]', asrx, icase)
  end

  def initialize(str, asregex, icase)
    @rawpattern = str
    @icase = icase
    @pattern = nil
    flags = nil
    if @icase then
      flags = "i"
    end
    if asregex then
      @pattern = @rawpattern
    else
      @pattern = Regexp.quote(@rawpattern)
    end
  end

  def oldmatch(str, &b)
    rt = []
    #shit = str.enum_for(:scan, @pattern).map{ Regexp.last_match.begin(0) }
    #return rt
    #b.call(shit)
    start_at = 0
    matches  = [ ]
    while(m = str.match(@pattern, start_at))
      rt.push(m) unless block_given?
      b.call(m) if block_given?
      start_at = m.end(0)
    end
    return rt
  end


end

class App

  def initialize(opts)
    @opts = opts
    @seenfiles = []
  end

  def search_line(ln, file, lno)
    @opts.patterns.each do |pat|
      pat.match(ln) do |m|
        $stdout.printf("%s:%d: %s\n", file, lno, ln.dump[1 .. -2].gsub('\\"', '"'))
      end
    end
  end

  def search_file(f)
    fs = File.stat(f)
    if not @seenfiles.include?(fs) then
      File.foreach(f).with_index do |line, lno|
        line.scrub!
        search_line(line, f, lno)
      end
      @seenfiles.push(fs)
    end
  end

  def search_directory(loc)
    Find.find(loc) do |path|
      next unless File.file?(path)
      search_file(path)
    end
  end

  def search(locations)
=begin
    locations.each do |loc|
      if File.file?(loc) then
        search_file(loc)
      elsif File.directory?(loc) then
        search_directory(loc)
      else
        $stderr.printf("error: not a file or directory: %p\n", loc)
      end
    end
=end
      # NB. default grep does not permit using more than one pattern with perl-style regular expressions.
      # but pcregrep does, so... we use pcregrep.
      cmd = ["grep", "-HrP"]
      #cmd = ["pcregrep", "-Hr"]

      if @opts.icase then
        cmd.push("-i")
      end
      if @opts.withlinenumbers then
        cmd.push("-n")
      end
      if @opts.forcetext then
        cmd.push("-a")
      end
      @opts.patterns.each do |pa|
        cmd.push("-e", pa.pattern)
      end
      if @opts.context != nil then
        cmd.push("-C#{@opts.context}")
      end
      if @opts.after != nil then
        cmd.push("-A#{@opts.after}")
      end
      if @opts.before != nil then
        cmd.push("-B#{@opts.before}")
      end
      if @opts.maxcount != nil then
        cmd.push("-m#{@opts.maxcount}")
      end
      cmd.push(*locations)
      cmdstr = cmd.map{|s| s }.join(" ")
      if cmdstr.length > 120 then
        cmdstr = cmdstr[0 .. 110] + " ..."
      end
      $stderr.printf("command: <<<%s>>>\n", cmdstr)
      exec(*cmd)
  end
end

begin
  opts = OpenStruct.new({
    icase: false,
    asrx: true,
    patterns: [],
    maxcount: nil,
    withlinenumbers: false,
    forcetext: false,
  })
  OptionParser.new{|prs|  
    prs.on("-h", "--help"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-i", "--icase"){
      opts.icase = true
    }
    prs.on("-m<n>"){|v|
      opts.maxcount = v.to_i
    }
    prs.on("-f<str>", "--hollerith=<str>"){|v|
      opts.patterns.push(Pattern.make_hollerith(v, opts.icase))
    }
    prs.on("-s<str>", "-q<str>", "--quot=<str>"){|v|
      opts.patterns.push(Pattern.make_quot(v, opts.asrx, opts.icase))
    }
    prs.on("-c<str>", "--split=<str>", "match split strings (i.e., ``if(str[0] == 'f' && str[1] == 'o' && str[2] == 'o')'')"){|v|
      opts.patterns.push(Pattern.make_split(v, opts.asrx, opts.icase))
    }
    prs.on("-q<str>", "--qsplit=<str>", "like --split, but with '\"' strings"){|v|
      opts.patterns.push(Pattern.make_qsplit(v, opts.asrx, opts.icase))
    }
    prs.on("--regex"){
      opts.asrx = true
    }
    prs.on("-C<n>", "--context=<n>"){|v|
      opts.context = v
    }
    prs.on("-A<n>", "--after=<n>"){|v|
      opts.after = v
    }
    prs.on("-B<n>", "--before=<n>"){|v|
      opts.before = v
    }
    prs.on("-n"){
      opts.withlinenumbers = true
    }
    prs.on("-a"){
      opts.forcetext = true
    }
  }.parse!
  if opts.patterns.empty? then
    $stderr.printf("not enough args\n")
    exit(1)
  else
    items = ARGV
    if items.empty? then
      items.push(".")
    end
    App.new(opts).search(items)
  end
  
end
