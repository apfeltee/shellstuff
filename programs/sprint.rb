#!/usr/bin/ruby

require "ostruct"
require "optparse"


def do_io(fh, opts)
  ofile = opts.ofile
  wt = opts.waittime
  fh.each_byte do |bt|
    ch = bt.chr rescue 0
    ofile.write(ch)
    ofile.flush
    if wt > 0.0 then
      sleep(wt)
    end
  end
end

def do_file(path, opts)
  begin
    File.open(path, "rb") do |fh|
      do_io(fh, opts)
    end
    return true
  rescue => ex
    $stderr.printf("sprint: failed to open %p for reading: (%s) %s\n", path, ex.class.name, ex.message)
  end
  return false
end

begin
  rc = 0
  opts = OpenStruct.new({
    ofile: $stdout,
    waittime: 0.0,
  })
  OptionParser.new{|prs|
    # TODO: calculate miroseconds properly. very broken atm
    prs.on("-<n>", "-t<n>", "--wait=<n>", "--sleep=<n>", "wait n microseconds between each call to write()"){|v|
      opts.waittime = (v.to_f / (100 * 10))
      $stderr.printf("v.to_f=%p, waittime=%p\n", v.to_f, opts.waittime)
      exit
    }
  }.parse!
  if ARGV.empty? then
    do_io($stdin)
  else
    ARGV.each do |arg|
      rc += (do_file(arg, opts) ? 0 : 1)
    end
  end
  exit(rc == 0)
end