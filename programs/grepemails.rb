#!/usr/bin/ruby --disable-gems

###
### !!!THIS IS JUST A LAZY COPY OF URLGREP!!!
###
### needs some serious work. probably?
###
###

require "ostruct"
require "optparse"

DEFAULT_ENCODING = "ASCII-8BIT"


REGEXP_LV1 = "@"
# URI::MailTo::EMAIL_REGEXP doesn't quote work right - it isn't really meant
# for extracting anyway...
REGEXP_LV3 = /\b((?<name>[\w+\-.]+)@(?<host>[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+))\b/i


class EmailGrep

  def initialize(opts)
    @options = opts
    @mails = []

  end

  def verbose(*msg)
    if @options.verbose then
      $stderr.printf("verbose: %s\n", sprintf(*msg))
    end
  end

  def do_file(path)
    if File.file?(path) then
      verbose("processing %p ...", path)
      File.open(path, "rb") do |fh|
        iter_io(path, fh)
      end
    else
      $stderr.puts("urlgrep: not a file: #{path.dump}")
    end
  end

  def do_stdin
    verbose("reading input from stdin")
    iter_io("<stdin>", $stdin)
  end

  def iter_io(path, io)
    ucount = 0
    doutfhack = (@options.utf16hack == true)
    ppath = File.basename(path)
    io.set_encoding(@options.encoding)
    io.each_line do |line|
      #line.scrub!
      if doutfhack then
        line.gsub!(/\0\0/, "\v")
        line.gsub!(/\0/, "")
      end
      begin
        if line.include?(REGEXP_LV1) then
          #m = line.match(REGEXP_LV3)
          #p m if m
          line.scan(REGEXP_LV3) do |chunk|
            uri = $&
            ucount += 1
            process_result(uri, path)
          end
        end
      rescue => ex
        $stderr.printf("err: exception: (%s) %s (line=%p)\n", ex.class.name, ex.message, line)
      end
    end
    if ucount > 0 then
      verbose("> found %d urls in %p", ucount, path)
    end
  end

  def process_result(uri, path)
    wantuniq = (@options.only_uniques == true)
    if wantuniq then
      if @mails.include?(uri) then
        return
      end
    end
    print_result(path, uri)
    if wantuniq then
      @mails.push(uri)
    end
  end

  def print_result(path, res)
    if (@options.noprint == true) && (@options.closefile == false) then
      # can i get uhhhhh contextual code?
    else
      printme = (@options.dump ? res.dump : res)
      if @options.printfilename then
        @options.outfile.printf("%s: ", path)
      end
      @options.outfile.printf("%s\n", printme)
    end
  end

  def print_stats()
    hostmap = Hash.new{|h, key| h[key] = [] }
    @mails.each do |str|
      begin
        m = str.match(REGEXP_LV3)
        if m == nil then
          $stderr.printf("should not have happened: failed to parse %p in #print_stats\n")
          exit(1)
        end
        host = m["host"]
        hostmap[host].push(str)
      rescue => ex
        $stderr.printf("error: URI.parse(%p) failed: (%s) %s\n", str, ex.class, ex.message)
      end
    end
    hostmap.sort_by{|host, uris| uris.length }.each do |host, uris|
      $stderr.printf("stats: %-5d %p\n", uris.length, host)
    end
  end
end

begin
  $stdin.sync = true
  $stdout.sync = true
  options = OpenStruct.new({
    dump: false,
    only_uniques: true,
    verbose: false,
    noprint: false,
    outfile: $stdout,
    closefile: false,
    encoding: DEFAULT_ENCODING,
    wantstats: false,
    utf16hack: false,
  })
  prs = OptionParser.new {|prs|
    prs.on("--utf16hack", "'handle' utf-16 by removing nulbytes in the string"){|_|
      options.utf16hack = true
    }
    prs.on("-u", "--[no-]unique", "print only unique URIs"){|v|
      options.only_uniques = v
    }
    prs.on("-d", "--[no-]dump", "use String#dump before printing each URI"){|v|
      options.dump = v
    }
    prs.on("-f", "--[no-]filename", "print filename before each line"){|v|
      options.printfilename = v
    }
    prs.on("-v", "--verbose", "toggle verbose mode"){|v|
      options.verbose = true
    }
    prs.on("-o<file>", "--out=<file>", "write to <file>"){|v|
      if v == "-" then
        options.noprint = true
      else
        options.outfile = File.open(v, "wb")
        options.closefile = true
      end
    }
    prs.on("-s", "--stats", "print statistics to stderr (implies '-v') - best used with '-o'"){|_|
      options.wantstats = true
      #options.verbose = true
    }
    prs.on("-e<str>", "--encoding=<str>", "set encoding"){|v|
      begin
        options.encoding = Encoding.find(v)
      rescue => ex
        $stderr.printf("error setting encoding: (%s) %s\n", ex.class.name, ex.message)
        exit(1)
      end
    }
  }
  prs.parse!
  begin
    ug = EmailGrep.new(options)
    if ARGV.empty? then
      ug.do_stdin
    else
      ARGV.each do |file|
        ug.do_file(file)
      end
    end
    if options.wantstats then
      ug.print_stats
    end
  ensure
    if options.closefile then
      options.outfile.close
    end
  end
end
