#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "base64"

#perl -pe 's/\b(\w+)\b\["(\w+)"\]/\1.\2/g'

module Utils
  MAX_STR_LEN = 25

  def self.shorten(str, dump=false)
    if str.length > MAX_STR_LEN then
      str = str[0 .. MAX_STR_LEN]
      str += "[...cut...]"
    end
    if dump then
      return str.dump
    end
    return str
  end
end

class UnfuckJS
  attr_reader :data

  def initialize(filedata, filename, wantinplace)
    @data = filedata.scrub
    @filename = filename
    @mustupdate = false
    @wantinplace = wantinplace
    fix_all
    if @wantinplace then
      File.write(@filename, @data)
    end
  end

  def log(fmt, *a, **kw)
    caller = caller_locations(1,1)[0]
    cname = caller.label
    cline = caller.lineno
    $stderr.printf("%s (line %d): %s\n", cname, cline, (
      if (a.empty? && kw.empty?) then
        fmt
      else
        sprintf(fmt, *a, **kw)
      end
    ))
  end

  def isfile?
    return ((@filename != nil) && File.file?(@filename))
  end

  def update
    if isfile? then
      log("updating ...")
      @data = File.read(@filename)
      @mustupdate = false
    end
  end

  # de-uglify javascript.
  # uses jsbeautifier - there is the original, for nodejs, and
  # one written in python - both use the same format for arguments, so
  # this shouldn't matter here. if your stuff breaks here, it's because
  # you probably don't have "js-beautify" in your path.
  def fix_beautify
    cmd = ["js-beautify", "-x", "--indent-size=4", "--brace-style=expand"]
    begin
      if @wantinplace then
        cmd.push("-r", @filename)
        system(*cmd)
        update
      else
        cmd.push("-")
        pipe = IO.popen(cmd, "r+")
        begin
          pipe.write(@data)
          pipe.close_write
        ensure
          @data = pipe.read
          #puts @data
          pipe.close
        end
      end
    rescue => ex
      log("failed to run 'js-beautify': (%s) %s", ex.class.name, ex.message)
    end
  end

  # detect things like
  #
  #   somevar["blargh"](somearg, someotherarg)
  #
  # that is, explicit object notation; and turn it into the js-y notation:
  #
  #   somevar.blargh(somearg, someotherarg)
  #
  # obv, the input doesn't have to be a function. it's just an example.
  def fix_quotnotation
    jsident = /[a-z_$][a-z0-9_$]+/i
    rx = /(\b#{jsident}\b)?\[["'](#{jsident})['"]\]/i
    log("starting ...")
    while @data.match?(rx) do
      @data.gsub!(rx, '\1.\2')
      log("repeating again")
    end
  end

  # detect and decode base64 encoded strings.
  def fix_base64
    cont = true
    ## insufficient: will match strings that are unlikely to be base64 (too greedy)
    #rx = /["'](?:[a-zA-Z0-9+\/]{4})*(?:|(?:[a-zA-Z0-9+\/]{3}=)|(?:[a-zA-Z0-9+\/]{2}==)|(?:[a-zA-Z0-9+\/]{1}===))['"]/
    ## insufficient: while better than above, still matches too many bogus strings
    #rx = /["']([-A-Za-z0-9+=]{1,50}|=[^=]|={3,})['"]/
    ## this one deliberately requires strings to end with "="; ergo, higher chance of matching
    ## legal base64 strings
    rx = /["']([a-zA-Z0-9+\/]+==?)['"]/
    log("starting ...")
    while cont do
      @data.gsub!(rx) do |str|
        log("str = %p (%d bytes)", Utils.shorten(str), str.bytesize)
        nq = str[1 .. -2]
        if nq.empty? || (nq[-1] != '=') then
          next str
        end
        begin
          next Base64.strict_decode64(nq).dump
        rescue => ex
          log("failed to decode %s: (%s) %s", Utils.shorten(nq, true), ex.class.name, ex.message)
          cont = false
          str
        end
      end
      if not @data.match?(rx) then
        return
      end
      log("repeating again ...")
    end
  end

  # there is no option for de-hexing hex-encoded strings, because
  # js-beautify already does that. neat.
  def fix_all
    fix_beautify
    fix_base64
    fix_quotnotation
    fix_beautify
  end
end

begin
  inplace = false
  haveoutfile = false
  ofh = $stdout
  $stdout.sync = true
  OptionParser.new{|prs|
    prs.on("-r", "-i", "--inplace", "--replace", "modify file(s) inplace"){
      inplace = true
    }
    prs.on("-o<file>", "--output=<file>", "write output to <file> instead of stdout"){|s|
      $stderr.printf("writing output to %p\n", s)
      haveoutfile = true
      ofh = File.open(s, "wb")
      #exit
    }
  }.parse!
  begin
    if ARGV.empty? then
      if $stdin.tty? then
        $stderr.printf("error: nothing piped, and no files specified\n")
        exit(1)
      else
        ofh.puts(UnfuckJS.new($stdin.read, nil, false).data)
      end
    else
      if haveoutfile && (ARGV.length > 1) then
        $stderr.printf("error: option '-o' can only be used with one file at a time\n")
        exit(1)
      else
        ARGV.each do |arg|
          uf = UnfuckJS.new(File.read(arg), arg, inplace)
          if not inplace then
            ofh.puts(uf.data)
          end
        end
      end
    end
  ensure
    if haveoutfile then
      ofh.close
    end
  end
end
