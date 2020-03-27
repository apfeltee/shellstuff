#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"

class Predefined
  Item = Struct.new(:name, :desc, :isre, :rxflags)

  class Item
    attr_reader :name, :pattern, :aliases, :desc, :isre, :flags

    def initialize(n, pattern, al=[], isr=false, fl="")
      @name = n
      @pattern = pattern
      @aliases = al
      @isre = isr
      @flags = fl
      @desc = "(no description specified)"
    end

    def d(s)
      @desc = s
      return self
    end

  end

  ITEMS = [
    ###
    # this pattern matches 'shar's, a.k.a., shell archives.
    # really ancient dumps were sometimes copied verbatim from usenet,
    # so they usually have a header of a mailing list; hence this pattern.
    # anyway, this applies to:
    #   sh, bash, ash, dash, zsh, ksh
    # (if you need support for more, then you misunderstood the idea of shell archives ...)
    # including these prefixes:
    #   /bin
    #   /usr/bin
    #   /usr/local/bin
    Item.new("shar",
      '^\s*#\s*((!\s*(/usr(/local)?)?/bin/([bd]?a|z|k|)?sh)|((.*)?\bshar\b\s*archive))', ["sh"], true, "i"
    ).d("match beginning of shell archives"),
  ]

  def get(name)
    ITEMS.each do |itm|
      if (itm.name == name) || itm.aliases.include?(name) then
        return itm
      end
    end
    return nil
  end  
end

def skip_io(fh, opts)
  #$stderr.printf("fh=%p, opts=%p\n", fh, opts)
  idx = 0
  iline = 1
  maywrite = false
  # cache opts, because OpenStruct access is surprisingly slow ...
  obegin = opts.ibegin
  oend = opts.iend
  strpattern = opts.strpattern
  out = opts.outhandle
  out.sync = true
  if strpattern != nil then
    if opts.useregex then
      fl = (
        if opts.regexflags.empty? then
          nil
        else
          opts.regexflags
        end
      )
      strpattern = Regexp.new(strpattern, fl)
    end
  end
  ####
  ## the two algorithms used here look very similar, and you
  ## may feel like you'd like to "improve" it, but i tell you:
  ##  DO NOT.
  ## i deliberately keep them separate to keep it maintainable.
  ####
  while true do
    alreadychecked = false
    # IO#readline raises EOFError, hence this block
    begin

      strline = fh.readline
      ######
      ## important: using a different algorithm for index-based skipping, to
      ## keep it at least somewhat maintainable!
      ######
      if strpattern != nil then
        # prevent unnecessary double checks
        if (not alreadychecked) && strline.match?(strpattern) then
          maywrite = true
          alreadychecked = true
          #strline = fh.readline
        end
        if maywrite then
          out.write(strline)
          out.flush
        end
      else
        ######
        ## this is the algorithm for the index-based skipping
        ######
        if (idx == obegin) then
          maywrite = true
        elsif ((oend != 0) && (idx == oend)) then
          maywrite = false
          # important: once oend is reached, there's no point in continuing to read
          return 0
        else
          if (maywrite == true) then
            out.write(strline)
            out.flush
          end
        end
      end
      idx += 1
      iline += 1
    rescue EOFError, Errno::EPIPE
      return 0
    end
  end
  return 0
end

def skip_file(fpath, opts)
  begin
    File.open(fpath, "rb") do |fh|
      return skip_io(fh, opts)
    end
  rescue Interrupt
    # nothing
    return 0
  rescue => ex
    $stderr.printf("skip_file: (%s) %s\n", ex.class.name, ex.message)
    return 1
  end
end

begin
  opts = OpenStruct.new({
    ibegin: 0,
    iend: 0,
    outhandle: $stdout,
    strpattern: nil,
    useregex: false,
    regexflags: "",
  })
  custoutput = false
  rtcode = 0
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-b<n>", "--begin=<n>", "start at line <n>"){|v|
      opts.ibegin = v.to_i
    }
    prs.on("-e<n>", "--end=<n>", "read until line <n>"){|v|
      opts.iend = v.to_i
    }
    prs.on("-s<str>", "--string=<str>", "skip until string <str> is found"){|v|
      opts.strpattern = v
    }
    prs.on("-r", "-x", "--regex", "treat option '-s' as a regular expression (only valid if '-s' is used)"){
      opts.useregex = true
    }
    prs.on("-f<str>", "--flags=<str>", "use flags <str> for regular expression (only valid if '-s' and '-r' is used)"){|v|
      opts.regexflags += v
    }
    prs.on("-o<path>", "--output=<path>", "write output to <path> instead of stdout"){|v|
      custoutput = true
      opts.outhandle = File.open(v, "wb")
    }
    prs.on("-p<name>", "--predefined=<name>", "use a predefined pattern for option '-s' (use '-p list' to list them) "){|v|
      name = v.strip.downcase
      if name == "list" then
        $stdout.printf("available predefined patterns:\n")
        Predefined::ITEMS.each do |itm|
          $stdout.printf("  - %-20s %s\n", itm.name, itm.desc)
        end
        exit(0)
      else
        pre = Predefined.new
        if (itm = pre.get(name)) == nil then
          $stderr.printf("error: -p: cannot find a predefined pattern named %p\n", v)
          exit(1)
        end
        opts.strpattern = itm.pattern
        opts.useregex = itm.isre
        opts.regexflags += itm.flags
      end
    }
  }.parse!
  begin
    #pp opts
    if ARGV.empty? then
      if $stdin.tty? then
        $stderr.printf("error: no files given, and nothing piped\n")
        exit(1)
      else
        rtcode += skip_io($stdin, opts)
      end
    else
      ARGV.each do |arg|
        rtcode += skip_file(arg, opts)
      end
    end
  ensure
    if custoutput then
      opts.outhandle.close
    end
  end
  exit(rtcode)
end

