#!/usr/bin/ruby

require "ostruct"
require "optparse"

DEFAULTS = OpenStruct.new({
  codec: "lavc",
  ext: "mp4",
})

# mencoder Stargate.SG1-s01e01\&e02.Children.of.the.Gods-part.1\&2.mkv -o Stargate.SG1-s01e01\&e02.Children.of.the.Gods-part.1\&2.mp4 -ovc lavc -oac lavc
def convert_full(fromfile, tofile, opts)
  cmd = [
    "mencoder", fromfile, "-o", tofile,
    "-oac", opts.codec,
    "-ovc", opts.codec,
  ].map(&:to_s)
  $stderr.printf("+ %s\n", cmd.map(&:dump).join(" "))
  system(*cmd)
end

def convert_autoname(fromfile, opts)
  ext = File.extname(fromfile)[1 .. -1]
  pstem = fromfile
  if (ext != "") then
    pstem = File.basename(fromfile, "."+ext)
  end
  tofile = (pstem + "." + opts.ext)
  return convert_full(fromfile, tofile, opts)
end

begin
  opts = OpenStruct.new({
    codec: DEFAULTS.codec,
    ext: DEFAULTS.ext,
    output: nil,
  })
  OptionParser.new{|prs|
    prs.on("-c<codec>", "--codec=<codec>", "use <codec> (default: #{DEFAULTS.codec})"){|v|
      opts.codec = v
    }
    prs.on("-o<path>", "--out=<path>", "set output file"){|v|
      opts.output = v
    }
  }.parse!
  if ARGV.length == 0 then
    $stderr.printf("need at least one filename\n")
    exit(1)
  else
    if opts.output != nil then
      if ARGV.length > 1 then
        $stderr.printf("'-o' can only be used with one file at a time")
        exit(1)
      else
        exit(convert_full(ARGV[0], opts.output, opts) ? 0 : 1)
      end
    else
      rc = 0
      ARGV.each do |arg|
        rc += (convert_autoname(arg, opts) ? 0 : 1)
      end
      exit(rc)
    end
  end
end
