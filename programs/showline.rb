#!/usr/bin/ruby

require "ostruct"
require "optparse"

class ShowLine

  def initialize(opts, file)
    @opts = opts
    @filelines = {}
    cnt = 1
    File.foreach(file) do |line|
      @filelines[cnt] = line
      cnt += 1
    end
  end

  def showline(lno)
    printf("%d\t%s", lno, @filelines[lno])
  end

end

begin
  rt = 0
  prog = File.basename($0)
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "print this help and exit"){
      puts(prs.help)
      exit(0)
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("usage: showline <file> <lineno> [<lineno> ...]\n", prog)
    exit(1)
  else
    file = ARGV.shift
    sl = ShowLine.new(opts, file)
    ARGV.each do |arg|
      lno = arg.to_i
      sl.showline(lno)
    end
  end
end

