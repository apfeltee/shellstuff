#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "fileutils"
require "zlib"
require "tempfile"

def iofmtfwd(out, postfmt, fmt, *args, **kw)
  str = (
    if args.empty? && kw.empty? then
      fmt
    else
      sprintf(fmt, *args, **kw)
    end
  )
  out.printf(postfmt, str)
end


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

class UnZlib
  def initialize(opts)
    @opts = opts
  end

  def warn(fmt, *args, **kw)
    iofmtfwd($stderr, "warning: %s\n", fmt, *args, **kw)
  end

  def fail(fmt, *args, **kw)
    iofmtfwd($stderr, "error: %s\n", fmt, *args, **kw)
    exit(1)
  end

  def maybefail(fmt, *args, **kw)
    if @opts.force then
      warn(fmt, *args, **kw)
    else
      fail(fmt, *args, **kw)
    end
  end

  def verbose(fmt, *args)
    if @opts.verbose then
      iofmtfwd($stderr, "-- %s\n", fmt, *args)
    end
  end

  def unzlib_io(inio, outio, chunksz: (1024 * 8), &block)
    zi  = Zlib::Inflate.new
    bycompr = 0
    bydecompr = 0
    lam = lambda{
      buf = inio.read(chunksz)
      if buf == nil then
        percentage = (((bydecompr.to_f - bycompr.to_f) / bydecompr) * 100.0)
        tags = {
          perc: percentage,
          fsco: filesize(bycompr),
          fsde: filesize(bydecompr),
          byco: bycompr,
          byde: bydecompr,
        }
        tags[:self]=tags
        #verbose("ratio: %f%% (compressed: %s (%d bytes), real: %s (%d bytes)) ",
          #percentage, filesize(bycompr), bycompr, filesize(bydecompr), bydecompr)
        verbose("ratio: %<perc>f%% (compressed: %<fsco>s (%<byco>d bytes), real: %<fsde>s (%<byde>d bytes))", **tags)
        return bydecompr
      else
        buflen = buf.length
        if buflen == 0 then
          verbose("buffer is null!")
        end
        bycompr += buflen
        inflated = zi.inflate(buf)
        bydecompr += outio.write(inflated)
      end
    }
    begin
      while true do
        #begin
          lam.call
=begin
        #rescue Zlib::NeedDict
          #zi.set_dictionary((("0" .. "z").to_a).join)
        rescue Zlib::DataError => ex
          if @opts.force then
            lam.call
          else
            raise ex
          end
=end
        end
      #end
    ensure
      zi.close
    end
  end

  def unzlib_file(filepath, outpath)
    File.open(filepath, "rb") do |inio|
      File.open(outpath, "wb") do |outio|
        unzlib_io(inio, outio)
      end
    end
  end

  def handle(infile)
    goodrx = /\.z$/i
    ext = File.extname(infile)
    if ext.match(goodrx) || ((@opts.ignoreext == true) || (@opts.force == true)) then
      destfile = File.basename(infile, ext)
      if File.file?(destfile) then
        if @opts.force then
          origdest = destfile.dup
          destfile = Dir::Tmpname.make_tmpname([File.join(File.dirname(origdest), infile)], nil)
          warn("destination file %p already exists -- renamed to %p", origdest, destfile)
        else
          fail("destination file %p already exists", destfile)
        end
      end
      verbose("inflating %p -> %p", infile, destfile)
      begin
        unzlib_file(infile, destfile)
        FileUtils.rm(infile) if @opts.deleteafter
      rescue => ex
        FileUtils.rm_f(destfile)
        fail("exception while inflating %p: (%s) %s", infile, ex.class, ex.message)
      end
    else
      fail("file %p has unknown extension %p", infile, ext)
    end
  end
end

begin
  opts = OpenStruct.new({
    deleteafter: false,
    force: false,
    verbose: true,
    ignoreext: false,
  })
  OptionParser.new{|prs|
    prs.on("-d", "--delete", "delete original file upon successful extraction"){|_|
      opts.deletafter = true
    }
    prs.on("-f", "--force", "force inflation, even if output file already exists"){|_|
      opts.force = true
    }
    prs.on("-v", "--verbose", "enable verbose messages"){|_|
      opts.verbose = true
    }
    prs.on("-x", "--ignoreext", "ignore file extension"){|_|
      opts.ignoreext = true
    }
  }.parse!
  unz = UnZlib.new(opts)
  if ARGV.empty? then
    if $stdout.tty? then
      $stderr.puts("no file(s) provided")
      exit(1)
    else
      unz.unzlib_io($stdin, $stdout)
    end
  else
    ARGV.each do |arg|
      if not File.file?(arg) then
        warn("argument %p is not a file - will be ignored", arg)
      else
        unz.handle(arg)
      end
    end
  end
end
