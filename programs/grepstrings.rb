#!/usr/bin/ruby

## searches files/stdin for quotation-character enclosed strings.
## mainly meant for reverse-engineered files, including, but not limited to:
## assembly
## other things
##
## this file is kind of a mess.


require "optparse"

## trial and error.
#STRING_REGEXP = Regexp.new("(\\\"(.*?)\\\"|\'(.*?)\')")
#STRING_REGEXP = /(?=["'])(?:"[^"\\]*(?:\\[\s\S][^"\\]*)*"|'[^'\\]*(?:\\[\s\S][^'\\]*)*')/
STRING_REGEXP = /(["'])((?:(?!\1)[^\\]|(?:\\\\)*\\[^\\])*)\1/

class String
  def isprint?
    return (self =~ /[^[:print:]]/)
  end
end

class GrepStrings
  def initialize(**options)
    @options = options
    @seen = []
  end

  def verbose(fmt, *args)
    str = if args.empty? then fmt else sprintf(fmt, *args) end
    if @options[:verbose] then
      $stderr.printf("verbose: %s\n", str)
    end
  end

  def do_io(io, filename)
    io.each_line.with_index do |line, lineno|
      line.scrub.scan(STRING_REGEXP).each do |match|
        #p match
        #data = match.shift
        #raw = match.shift
        #rest = match
        quot = match[0]
        realraw = match[1]
        raw = (quot + realraw + quot)
        data = realraw #.gsub(/^["']/, "").gsub(/["']$/, "")
        if not raw.nil? then
          if @options[:printonly] then
            next if (not raw.ascii_only?)
          end
          if @options[:unique] then
            # this is kept deliberately separately to improve performance
            if @options[:nocase] then
              next if @seen.include?(raw)
              @seen.push(raw)
            else
              sraw = raw.downcase
              next if @seen.include?(sraw)
              @seen.push(sraw)
            end
          end
          if @options[:printfilename] then
            $stdout.printf("%s: ", filename)
          end
          if @options[:printlineno] then
            $stdout.printf("%d: ", lineno+1)
          end
          if @options[:printwholeline] then
            $stdout.puts(line)
          else
            $stdout.puts(@options[:printraw] ? raw : data )
          end
        end
      end
    end
  end
end

begin
  $stdout.sync = true
  options = {
    unique: true,
    nocase: false,
    printonly: true,
    printraw: false,
    printfilename: false,
    verbose: false,
    printlineno: false,
  }
  prs = OptionParser.new{|prs|
    prs.on("-u", "--[no-]unique", "print only unique strings"){|v|
      options[:unique] = v
    }
    prs.on("-i", "--[no-]case-insensitive", "ignore case when -u is specified (implies '-u')"){|v|
      options[:unique] = true
      options[:nocase] = v
    }
    prs.on("-r", "--[no-]print-raw", "print raw (quoted) string, instead of content only"){|v|
      options[:printraw] = v
    }
    prs.on("-p", "--[no-]printable-only", "print only ascii strings"){|v|
      options[:printonly] = v
    }
    prs.on("-v", "--verbose", "enable verbose messages"){|v|
      options[:verbose] = true
    }
    prs.on("-f", "--printfilename", "print filename"){|v|
      options[:printfilename] = true
    }
    prs.on("-n", "--printlineno", "print line number"){
      options[:printlineno] = true
    }
    prs.on("-l", "print whole line"){
      options[:printwholeline] = true
    }
  }
  prs.parse!
  grep = GrepStrings.new(**options)
  if ARGV.empty? then
    if $stdin.tty? then
      $stderr.puts("ERROR: no input files given, and no pipe present!")
      $stderr.puts(prs.help)
      exit(1)
    else
      grep.do_io($stdin, "<stdin>")
    end
  else
    ARGV.each do |filename|
      if File.file?(filename) then
        File.open(filename, "rb") do |fh|
          grep.verbose("processing %p ...", filename)
          begin
            grep.do_io(fh, filename)
          rescue => ex
            $stderr.printf("exception reading %p: (%s) %s\n", filename, ex.class.name, ex.message)
          end
        end
      else
        $stderr.printf("warning: not a file: %p\n", filename)
      end
    end
  end
end
