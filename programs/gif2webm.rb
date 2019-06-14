#!/usr/bin/ruby

require "ostruct"
require "optparse"

# ffmpeg -i your_gif.gif -c:v libvpx -crf 12 -b:v 500K output.webm

def filesize(size)
  units = ['B', 'K', 'M', 'G', 'T', 'P', 'E']
  if size == 0 then
    return '0B'
  end
  exp = (Math.log(size) / Math.log(1024)).to_i
  if exp > 6 then
    exp = 6
  end
  return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
end

def mkofile(infile)
  spl = infile.split(".")
  nx = spl.pop
  if nx !~ /^gif$/i then
    $stderr.printf("mkofile: nx %p of %p isn't 'gif'? should not happen!\n", nx, infile)
    exit(1)
  end
  return [*spl, "webm"].join(".")
end

def gif2webm(infile, opts)
  ofile = (opts.ofile || mkofile(infile))
  cmd = [
    "ffmpeg", "-i", infile,
    "-c:v", "libvpx",
    "-crf", opts.crf,
    "-b:v", opts.bitrate,
    "-auto-alt-ref", 0,
    ofile
  ].map(&:to_s)
  $stderr.printf("running: %s\n", cmd.map(&:dump).join(" "))
  return system(*cmd)
end

def isgif(file)
  if File.file?(file) then
    if File.extname(file).match(/\.gif$/i) then
      return true
    end
  end
  return false
end

begin
  rc = 0
  opts = OpenStruct.new({
    bitrate: "500K",
    crf: 12,
  })
  OptionParser.new{|prs|
    prs.on("-c<n>", "--crf=<n>", "specify constant rate factor (crf) - lower values mean better quality, but also bigger size"){|v|
      iv = v.to_i
      if (iv < 4) || (iv > 63) then
        $stderr.printf("error: specified rate factor %p must be a numeric value between 4 and 63\n", v)
        exit(1)
      end
      opts.crf = iv
    }
    prs.on("-b<s>", "--bitrate=<s>", "bitrate; higher values mean better quality, but also bigger size"){|v|
      if v.match(/^\d+$/) then
        opts.bitrate = filesize(v)
      elsif v.match(/^\d+\w$/) then
        opts.bitrate = v
      else
        $stderr.printf("error: specified bitrate %p appears to errornously formatted\n", v)
        exit(1)
      end
    }
  }.parse!
  begin
    if ARGV.empty? then
      $stderr.printf("usage: %s [<opts>] <files ...>\n", File.basename($0))
      exit(1)
    else
      ARGV.each do |arg|
        if isgif(arg) then
          if not gif2webm(arg, opts) then
            rc += 1
          end
        else
          if not File.file?(arg) then
            $stderr.printf("error: file %p does not exist\n", arg)
          else
            $stderr.printf("error: file %p is not a GIF file\n", arg)
          end
          rc += 1
        end
      end
    end
  ensure
    exit(rc > 0 ? 1 : 0)
  end
end


