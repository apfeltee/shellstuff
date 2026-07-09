#!/usr/bin/ruby

require "ostruct"
require "optparse"

CARET_CHARS = (
  "@ABC.I.?...KLMNO" +
  "PQRS.JH.XY.." +
  "\\]^_" +
  "......W[.....EFG" +
  "..V....D....TU.Z"
)

def gcont(b)
  # 10 = "\n"
  # 32 = " "
  if (b >= CARET_CHARS.length) || ((b == 10) || (b == 32)) then
    return nil
  end
  #return ("^" + CARET_CHARS[b])
  return CARET_CHARS[b]
end

class CatFile
  def initialize(hnd, filename, outhnd, opts)
    @opts = opts
    @hnd = hnd
    @outhnd = outhnd
    # make use of ruby's String#dump to make the filename "safe" (-ish).
    # without the quotes, obviously.
    @filename = File.basename(filename).dump[1 .. -2]
    @counter = 1
  end

  def read_line()
    begin
      return @hnd.readline
    rescue
      return nil
    end
  end

  # stuff to be done before printing a line.
  def print_before()
    if @opts.prefixfile then
      @outhnd.printf("%s:", @filename)
    end
    if @opts.prefixlinenumbers then
      @outhnd.printf("%-5d:", @counter)
      @counter += 1
    end
  end

  # when the line contents itself are not further being looked at.
  # in other words, read line then write line.
  def print_normal(line)
    @outhnd.write(line)
    @outhnd.flush
  end

  def print_caret(line)
    line.each_byte do |b|
      cc = make_caret(b)
      if cc then
        @outhnd.write("^")
        @outhnd.write(cc)
      else
        @outhnd.write(b.chr)
      end
    end
    @outhnd.write("\n")
  end

  def print_line(line)
    print_before()
    if @opts.nonprint then
      print_caret(line)
    else
      print_normal(line)
    end
  end

  def walk_lines
    while true do
      line = read_line()
      if line == nil then
        return
      else
        print_line(line)
      end
    end
  end

  def run
    walk_lines
  end
end

begin
  ec = 0
  closeout = false
  outhandle = $stdout
  opts = OpenStruct.new({
    prefixlinenumbers: false,
    prefixfile: false,
    nonprint: false,
    
  })

  OptionParser.new{|prs|
=begin
  -A, --show-all           equivalent to -vET
  -b, --number-nonblank    number nonempty output lines, overrides -n
  -e                       equivalent to -vE
  -E, --show-ends          display $ at end of each line
  -n, --number             number all output lines
  -s, --squeeze-blank      suppress repeated empty output lines
  -t                       equivalent to -vT
  -T, --show-tabs          display TAB characters as ^I
  -u                       (ignored)
  -v, --show-nonprinting   use ^ and M- notation, except for LFD and TAB

=end
    prs.on("-h", "--help"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-o<file>", "--output=<file>"){|v|
      begin
        outhandle = File.open(v, "wb")
        closeout = true
      rescue => ex
        $stderr.printf("%s: cannot open %p for output: (%s) %s\n", File.basename($0), v, ex.class.name, ex.message)
        exit(1)
      end
    }
    prs.on("-v", "--show-nonprinting", "use caret-notation for non-printable characters"){
      opts.nonprint = true
    }
    prs.on("-n", "--number"){
      opts.prefixlinenumbers = true
    }
    prs.on("-f", "--filename"){
      opts.prefixfile = true
    }
  }.parse!
  outhandle.sync = true
  begin
    if ARGV.empty? then
      CatFile.new($stdin, "<stdin>", outhandle, opts).run
    else
      i = 0
      ARGV.each do |a|
        begin
          File.open(a, "rb") do |fh|
            CatFile.new(fh, a, outhandle, opts).run
          end
        rescue => ex
          $stderr.printf("%s: failed to open %p: (%s) %s\n", File.basename($0), a, ex.class.name, ex.message)
          ec += 1
        end
        if (i + 1) != ARGV.length then
          outhandle.write("-------\n")
        end
        i += 1
      end
    end
  ensure
    if closeout then
      outhandle.close
    end
  end
  exit(ec > 0 ? 1 : 0)
end



