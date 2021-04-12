#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "addressable/uri"
require "curb"

DEFAULT_OFILE = "index.html"

module Util
  def self.size_to_readable(size)
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
end

class CGet
  KNOWNMIMES = {
    "text/html" => "html",
    "text/plain" => "txt",
    "text/xml" => "xml",
    "image/png" => "png",
    "image/jpeg" => "jpg",
    "image/gif" => "gif",
    "application/xml" => "xml",
  }

  def initialize(opts, url)
    @opts = opts
    @url = Addressable::URI.parse(url)
    @curl = Curl::Easy.new(@url)
    @outputfile = @opts.outputfile
    @outputhandle = nil
    @outputshouldclose = false
    @content_mimetype = nil
    @content_ishtml = false
    @can_write = false
    @have_warned = false
    $stderr.printf("cget:url: %p\n", url)
    configure
    @curl.on_header{|data| handle_header(data) }
    @curl.on_body{ |data| handle_body(data) }
    @curl.on_redirect{|*a| $stderr.printf("on_redirect: a: %p\n", a) }
  end

  def cleanup
    if @outputshouldclose then
      if @outputhandle != nil then
        @outputhandle.close
      end
    end
  end

  def configure
    if @opts.to_stdout then
      @outputhandle = $stdout
    else
      if @opts.outputfile then
        # if -o specified explicitly, skip checking ...
        #@outputfile = check_ofile(@opts.outputfile)
        @outputfile = @opts.outputfile
      end
    end
    if @opts.use_http2 then
      @curl.set(:HTTP_VERSION, Curl::HTTP_2_0)
    end
    if @opts.use_progress then
      @curl.on_progress{|*a|
        next progress_func($stderr, *a)
      }
      @curl.on_complete{
        $stderr.printf("finished\n")
        next 0
      }
    end
    @curl.ssl_verify_peer = (not @opts.no_sslverify)
    @curl.follow_location = @opts.follow_location
  end

  def progress_func(ofh, totaltodownload, nowdownloaded, totaltoupload, nowuploaded)
    # ensure that the file to be downloaded is not empty
    # because that would cause a division by zero error later on
    if (totaltodownload <= 0.0) then
        return 0;
    end
    # how wide you want the progress meter to be
    totaldotz = 40
    fractiondownloaded = nowdownloaded / totaltodownload
    # part of the progressmeter that's already "full"
    dotz = (fractiondownloaded * totaldotz).to_i
    # create the "meter"
    ii = 0
    hstotal = Util.size_to_readable(totaltodownload)
    hsnow = Util.size_to_readable(nowdownloaded)
    percentage = (fractiondownloaded * 100)
    # NB. showing percentage as first string can be used by some
    # terminal emulators to show percentage in the caption
    ofh.printf("%3.0f%% (%s of %s) [", percentage, hsnow, hstotal)
    ofh.flush
    # part  that's full already
    #for ( ; ii < dotz;ii++) {
    (ii .. dotz).each do
      ofh.printf("=")
      ofh.flush
    end
    # remaining part (spaces)
    #for ( ; ii < totaldotz;ii++) {
    (ii .. totaldotz).each do
      ofh.printf(" ")
      ofh.flush
    end
    # and back to line begin - do not forget the fflush to avoid output buffering problems!
    ofh.printf("]\r")
    ofh.flush
    # if you don't return 0, the transfer will be aborted - see the documentation
    return 0
  end


  def msg(fmt, *args)
    $stderr.printf("-- %s\n", sprintf(fmt, *args))
  end

  def check_ofile(file)
    if File.file?(file) then
      dir = File.dirname(file)
      base = File.basename(file)
      ext = File.extname(base)
      stem = File.basename(base, ext)
      ci = 1
      while true do
        nfile = sprintf("%s.%d%s", stem, ci, ext)
        if not File.file?(nfile) then
          msg("output file %p already exists, renaming to %p", file, nfile)
          return nfile
        end
        ci += 1
      end
    end
    return file
  end

  def open_outputfile()
    begin
      if @outputhandle == nil then
        @outputhandle = File.open(@outputfile, "wb")
        msg("writing to %p", @outputfile)
        @outputshouldclose = true
      end
    rescue => ex
      msg("ERROR: could not open %p for writing: (%s) %s", @outputfile, ex.class.name, ex.message)
    end
  end

  def guess_ext_from_mimetype
    if @content_mimetype != nil then
      if (ext = KNOWNMIMES.fetch(@content_mimetype, nil)) != nil then
        return ext
      end
    end
    return "bin"
  end

  def check_outputfile
    if @outputhandle == nil then
      if @outputfile == nil then
        if (@url.host == nil) then
          @outputfile = check_ofile(DEFAULT_OFILE)
        else
          host = @url.host.scrub.downcase
          path = @url.path.scrub
          query = @url.query
          haspath = (
            (path != "") &&
            (path != "/") &&
            (path != nil)
          )
          if haspath then
            base = File.basename(path)
            if path.match?(/\.\w+$/) then
              @outputfile = check_ofile(base)
            else
              ext = guess_ext_from_mimetype
              @outputfile = check_ofile(sprintf("%s.%s", base, ext))
            end
          else
            bits = [host.gsub(/[^[a-z0-9]]/i, ""), "_", DEFAULT_OFILE].join
            msg("path: either empty or nil; using %p", bits)
            @outputfile = check_ofile(bits)
          end
        end
      end
    end
    open_outputfile
  end

  def parse_content_disposition(hd)
    parts = hd.split(":").map(&:strip).reject(&:empty?)
    parts.shift
    if (m = parts[0].match(/filename=(?:"(?<filename>.*?)"|(?<filename>[^;\r\n]*))/i)) == nil then
      msg("ERROR: failed to parse content-disposition header: %p", hd)
      exit(1)
    else
      fn = m["filename"].strip
      while (fn.match?(rxbegin=/^["'\/\\]/) || fn.match?(rxend=/["'\/\\]$/)) do
        if fn.match?(rxbegin) then
          fn = fn[1 .. -1]
        end
        if fn.match?(rxend) then
          fn = fn[0 .. -2]
        end
      end
      @outputfile = check_ofile(fn)
      msg("parsed content-disposition; output file is %p", @outputfile)
    end
  end

  def parse_content_type(hd)
    # de-parse stuff like "text/html; ..."
    # split at ":", strip each chunk, remove empty chunks, take first, split at ";", strip
    @content_mimetype = hd.split(":").map(&:rstrip).reject(&:empty?)[1].split(";")[0].strip
    if @content_mimetype.match?(/text\/htm?/i) then
      @content_ishtml = true
    end
  end

  def handle_header(data)
    hd = data.scrub.rstrip
    $stderr.printf("Header: %s\n", hd.dump[1 .. -2])
    if (m = hd.match(/HTTP\/([\d\.]+)\s*(?<status>\d+)/)) != nil then
      status = m["status"].strip.to_i
      if status == 200 then
        @can_write = true
      end
    elsif (hd != nil) && (hd != "") then
      if hd.match?(/^content-disposition:/i) then
        if (@outputhandle == nil) then
          parse_content_disposition(hd)
        end
      elsif hd.match?(/^content-type:/i) then
        parse_content_type(hd)
      end
    end
    return data.length
  end

  def handle_body(data)
    if @can_write then
      check_outputfile
      @outputhandle.write(data)
    else
      if @have_warned == false then
        $stderr.printf("**\n")
        $stderr.printf("** received bad HTTP status, no output file will be written **\n")
        $stderr.printf("**\n")
        @have_warned = true
      end
    end
    return data.length
  end

  def run
    begin
      @curl.perform
    rescue => ex
      $stderr.printf("EXCEPTION: (%s) %s\n", ex.class.name, ex.message)
      @can_write = false
    end
  end
  
end

begin
  opts = OpenStruct.new({
    outputfile: nil,
    no_sslverify: false,
    use_http2: true,
    use_progress: true,
    follow_location: true,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-o<file>", "--output=<file>", "explicitly set output file"){|v|
      if v == "-" then
        opts.to_stdout = true
      else
        opts.outputfile = v
      end
    }
    prs.on("-k", "--insecure", "disable SSL verification"){
      opts.no_sslverify = true
    }
    prs.on("-L", "--nofollow", "do NOT follow redirects") {
      opts.follow_location = false
    }
    prs.on("--noprogress", "disable progress bar"){
      opts.use_progress = false
    }
  }.parse!
  if ARGV.empty? then
    $stderr.puts("no urls provided. try 'cget -h'\n")
    exit(1)
  else
    ARGV.each do |arg|
      cg = CGet.new(opts, arg)
      begin
        cg.run
      ensure
        cg.cleanup
      end
    end
  end
end
