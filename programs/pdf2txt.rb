#!/usr/bin/ruby

require "rubygems"
require "ostruct"
require "optparse"
require "pdf/reader"

def pdf_to_text(file, opts)
  browser = PDF::Reader.new(file)
  browser.pages.each_with_index do |page, i|
    text = page.text rescue "<<ERROR>>"
    text.strip! if opts.striptext
    opts.out.puts(text)
  end
end

begin
  $stdout.sync = true
  filehandle = $stdout
  opts = OpenStruct.new({
    out: $stdout,
    outputpath: nil,
    striptext: true,
  })
  prs = OptionParser.new {|prs|
    prs.on("-o<path>", "--outputfile=<path>", "set output file to <path>"){|v|
      opts.outputpath = v
    }
    prs.on("-s", "--nostrip", "do not strip text"){|_|
      opts.striptext = false
    }
  }
  prs.parse!
  if ARGV.empty? then
    if not $stdin.tty? then
      pdf_to_text($stdin, opts)
    else
      puts(prs.help)
    end
  else
    if (not opts[:outputpath].nil?) && (ARGV.length > 1) then
      $stderr.puts("cannot use '-o' with more than one file")
      exit(1)
    else
      if not opts.outputpath.nil? then
        begin
          filehandle = File.open(opts.outputpath, "wb")
        rescue => e
          $stderr.printf("cannot open %p for writing: (%s) %s\n", opts.outputpath, e.class, e.message)
          exit(1)
        end
      end
    end
    begin
      ARGV.each do |file|
        File.open(file, "rb") do |fh|
          pdf_to_text(fh, opts)
        end
      end
    ensure
      if not opts.outputpath.nil? then
        filehandle.close
      end
    end
  end
end

=begin
if ARGV.empty?
  browser = PDF::Reader.new($stdin)
else
  browser = PDF::Reader.new(ARGV[0])
end
browser.pages.each do |page|
  puts page.text
end
=end