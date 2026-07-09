#!/usr/bin/ruby

require "ostruct"
require "optparse"

class ExpandInclude
  def initialize(opts)
    @opts = opts
    @seen = []
    @cnt = 1
  end

  def expand(file, ismain)
    st = File.stat(file)
    if @opts.skipduplicates then
      if @seen.include?(st) then
        return
      end
    end
    actual_expand(file, ismain)
  end

  def actual_expand(file, ismain)
    File.open(file, "rb") do |fh|
      fh.each_line do |ln|
        m = ln.scrub.match(/^\s*#\s*include\s*[<"'](?<filename>.*)['">]/)
        if m then
          if @opts.addlines then
            $stdout.printf("#line %d %p (from %p)\n", @cnt, m["filename"], file)
          end
          expand(m["filename"], false)
        else
          if ln.strip.empty? && @opts.skipempty then
            next
          end
          $stdout.puts(ln)
        end
        if ismain then
          @cnt += 1
        end
      end
    end
  end
end

begin
  opts = OpenStruct.new({
    skipduplicates: false,
    skipempty: false,
    addlines: false,
  })
  OptionParser.new{|prs|
    prs.on("-d", "--nodupes", "skip previously #included files"){
      opts.skipduplicates = true
    }
    prs.on("-s", "--strip", "do not print empty lines"){
      opts.skipempty = true
    }
    prs.on("-l", "--lines", "add #line directive(s)"){
      opts.addlines = true
    }
  }.parse!
  ei = ExpandInclude.new(opts)
  if ARGV.empty? then
    $stderr.printf("no files provided. try --help\n")
    exit(1)
  end
  ARGV.each do |file|
    ei.expand(file, true)
  end
end
