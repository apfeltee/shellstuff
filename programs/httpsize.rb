#!/usr/bin/ruby

require "optparse"
require "http"

class Summarize
  attr_reader :total

  def initialize(sum, v)
    @total = 0
    @summarize = sum
    @verbose = v
  end

  def readable_size(size)
    # byte, kilobyte, megabyte, gigabyte, terabyte, petabyte, exabyte, zettabyte
    # the last two seem... unlikely, tbh
    units = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']
    if (size == 0) then
      return '0B'
    end
    exp = (Math.log(size) / Math.log(1024)).to_i
    if (exp > 6) then
      exp = 6
    end
    return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
  end

  def get_content_size(url)
    $stderr.printf("get %p ... ", url)
    begin
      r = HTTP.follow(true).get(url)
      cs = r["Content-Length"]
      if (cs != nil) then
        ics = cs.to_i
        $stderr.printf("content-size=%d (%s)", ics, readable_size(ics))
        return cs.to_i
      else
        $stderr.printf("content-size missing!")
      end
    rescue => e
      $stderr.printf("failed: %s", url, e.message)
    ensure
      $stderr.printf("\n")
    end
    return 0
  end

  def process(url)
    rc = get_content_size(url)
    @total += rc
    if !@summarize || @verbose then
      $stdout.printf("%s\t%s\n", readable_size(rc), url)
      $stdout.flush
    end
  end

  def print_summary()
    $stdout.printf("%s\ttotal\n", readable_size(@total))
  end
end


begin
  inputfile = nil
  summarize = false
  verbose = false
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-i<file>", "--input=<file>"){|v|
      inputfile = v
    }
    prs.on("-s", "--summarize"){
      summarize = true
    }
    prs.on("-v", "--verbose"){
      verbose = true
    }
  }.parse!
  s = Summarize.new(summarize, verbose)
  begin
    if inputfile != nil then
      File.foreach(inputfile) do |line|
        line.scrub!
        line.strip!
        s.process(line)
      end
    else
      if ARGV.empty? then
        $stderr.printf("need a URL here\n")
        exit(1)
      else
        ARGV.each do |url|
          print_content_size(url)
        end
      end
    end
  rescue Exception, Interrupt => e
    $stderr.printf("error: %s\n", e.message)
  ensure
    if summarize then
      s.print_summary()
    end
  end
end
