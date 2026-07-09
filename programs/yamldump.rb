#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "yaml"
require "pp"

def do_handle(hnd, opts)
  doc = YAML.load(hnd)
  if opts.pretty then
    pp(doc)
  else
    puts(doc)
  end
end

def do_file(path, opts)
  File.open(path, "rb") do |fh|
    do_handle(fh, opts)
  end
end

begin
  ec = 0
  opts = OpenStruct.new({
    pretty: true,
  })
  OptionParser.new{|prs|
    prs.on("-i", "read from stdin"){
      opts.force_stdin = true
    }
  }.parse!
  first = ARGV.shift
  if opts.force_stdin then
    do_handle($stdin, opts)
    if !first then
      exit(0)
    end
  end
  if (first == nil) then
    $stderr.printf("too few arguments. try '--help'\n")
    exit(1)
  end
  [first, *ARGV].each do |arg|
    if !do_file(arg, opts) then
      ec += 1
    end
  end
  exit((ec > 0) ? 1 : 0)
end
