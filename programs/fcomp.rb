#!/usr/bin/ruby

require "ostruct"
require "optparse"

class Sameness
  attr_reader :index, :count

  def initialize(index, count)
    @index = index
    @count = count
  end
end

class FileCompare
  def initialize(opts, fpath1, fpath2)
    @opts = opts
    @fpath1 = fpath1
    @fpath2 = fpath2
    @fh1 = File.open(@fpath1, "rb")
    @fh2 = File.open(@fpath2, "rb")
    @ch1 = nil
    @ch2 = nil
    @eof1 = false
    @eof2 = false
    @fsize1 = 0
    @fsize2 = 0
    @mustfinish = false
    @samestack = []
    @samecount = 0
    @totalindex = 0
    @totalsame = 0
    @finalscore = 0
  end

  def cleanup
    @fh1.close
    @fh2.close
  end

  def getc(hnd, &b)
    ch = hnd.getc
    if ch == nil then
      b.call
    end
    return ch
  end

  def readmore
    @ch1 = getc(@fh1){ @eof1 = true }
    @ch2 = getc(@fh2){ @eof2 = true }
    @fsize1 += 1 unless @eof1
    @fsize2 += 1 unless @eof2
    if @eof1 || @eof2 then
      @mustfinish = true
      $stderr.printf("stopping: ")
      if (@eof1 && (not @eof2)) || (@eof2 && (not @eof1)) then
        fbefore = (if @eof1 then @fpath1 else @fpath2 end)
        fafter = (if @eof1 then @fpath2 else @fpath1 end)
        $stderr.printf("file %p reached EOF before %p\n", fbefore, fafter)
      else
        $stderr.printf("both files reached EOF at the same length\n")
      end
    end
  end

  def reportfinal
    $stderr.printf("---[ final report ]---\n")
    if @samestack.empty? then
      $stderr.printf("there is no calculable similarity between %p and %p.\n", @fpath1, @fpath2)
    else
      $stderr.printf("in total, %d bytes were the same. below the sameness stack:\n", @totalsame)
      @samestack.each.with_index do |same, i|
        $stderr.printf("%-5d: until index %d, %d bytes were equal\n", i, same.index, same.count)
      end
    end
  end

  def main
    begin
      while not @mustfinish do
        readmore
        if (@ch1 == @ch2) then
          @samecount += 1
        else
          if @opts.wantdiffreport then
            $stderr.printf("found difference at index %<i>d: %<f1>p[%<i>d]=%<ch1>p, %<f2>p[%<i>d]=%<ch2>p\n", **{
              f1: @fpath1,
              f2: @fpath2,
              ch1: @ch1,
              ch2: @ch2,
              i: @totalindex,
            })
          end
          if @samecount > 0 then
            if @samecount >= @opts.atleast then
              @samestack.push(Sameness.new(@totalindex, @samecount))
              @totalsame += @samecount
            end
            @samecount = 0
          end
        end
        @totalindex += 1
      end
    ensure
      reportfinal
    end
  end
end

begin
  opts = OpenStruct.new({
    atleast: 2,
    wantdiffreport: false,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-m<d>", "--minimum=<d>", "--atleast=<d>", "only push if there is at least <d> similar bytes (default: 2)"){|v|
      opts.atleast = v.to_i
    }
    prs.on("-d", "--diff", "show messages about difference of individual bytes"){
      opts.wantdiffreport = true
    }
  }.parse!
  f1 = ARGV.shift
  f2 = ARGV.shift
  if f2.nil? then
    $stderr.printf("usage: fcomp <file1> <file2>\n")
    exit(1)
  end
  fc = FileCompare.new(opts, f1, f2)
  begin
    fc.main
  ensure
    fc.cleanup
  end
end

