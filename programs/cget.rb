#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "addressable/uri"
require "curb"

DEFAULT_OFILE = "index.html"



class CGet

  def initialize(opts, url)
    @opts = opts
    @url = Addressable::URI.parse(url)
    @curl = Curl::Easy.new(@url)
    @outputfile = nil
    @outputhandle = nil
    @content_ishtml = false
    configure
    @curl.on_header{|data| handle_header(data) }
    @curl.on_body{ |data| handle_body(data) }
  end

  def configure
    if @opts.outputfile then
      @outputfile = @opts.outputfile
    end
    if @opts.use_http2 then
      @curl.set(:HTTP_VERSION, Curl::HTTP_2_0)
    end
    @curl.ssl_verify_peer = (not @opts.no_sslverify)
    @curl.follow_location = @opts.follow_location
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

  def open_outputfile
    begin
      if @outputhandle == nil then
        @outputhandle = File.open(@outputfile, "wb")
      end
    rescue => ex
      msg("ERROR: could not open %p for writing: (%s) %s", @outputfile, ex.class.name, ex.message)
    end
  end

  def check_outputfile
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
          (path == nil)
        )
        if haspath && path.match?(/\.\w+$/) then
          base = File.basename(path)
          msg("path: using URL path %p", base)
          @outputfile = check_ofile(base)
        else
          bits = [host.gsub(/[^[a-z0-9]]/i, ""), "_", DEFAULT_OFILE].join
          msg("path: either empty or nil; using %p", bits)
          @outputfile = check_ofile(bits)
        end
      end
      open_outputfile
    end
  end

  def parse_content_disposition(hd)
    parts = hd.split(":").map(&:strip).reject(&:empty?)
    parts.shift
    if (m = parts[0].match(/attachment\s*;\s*filename=[\x22\x27](?<filename>.*?)[\x22\x27]/i)) == nil
      msg("ERROR: failed to parse content-disposition header: %p", hd)
      exit(1)
    else
      @outputfile = check_ofile(m["filename"].strip)
      msg("parsed content-disposition; output file is %p", @outputfile)
      open_outputfile
    end
  end

  def parse_content_type(hd)
    # de-parse stuff like "text/html; ..."
    # split at ":", strip each chunk, remove empty chunks, take first, split at ";", strip
    actualmime = hd.split(":").map(&:rstrip).reject(&:empty?)[1].split(";")[0].strip
    if actualmime.match?(/text\/htm?/i) then
      @content_ishtml = true
    end
  end

  def handle_header(data)
    hd = data.scrub.rstrip
    if (hd != nil) && (hd != "") then
      $stderr.printf("Header: %p\n", hd)
      if hd.match?(/^content-disposition:/i) then
        if (@outputfile == nil) then
          parse_content_disposition(hd)
        end
      elsif hd.match?(/^content-type:/i) then
        parse_content_type(hd)
      end
    end
    return data.length
  end

  def handle_body(data)
    check_outputfile
    @outputhandle.write(data)
    return data.length
  end

  def run
    @curl.perform
  end
  
end

begin
  opts = OpenStruct.new({
    outputfile: nil,
    no_sslverify: false,
    use_http2: true,
    follow_location: true,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-o<file>", "--output=<file>", "explicitly set output file"){|v|
      opts.outputfile = v
    }
    prs.on("-k", "--insecure", "disable SSL verification"){
      opts.no_sslverify = true
    }
    prs.on("-L", "--nofollow", "do NOT follow redirects") {
      opts.follow_location = false
    }
  }.parse!
  if ARGV.empty? then
    $stderr.puts("no urls provided. try 'cget -h'\n")
    exit(1)
  else
    ARGV.each do |arg|
      CGet.new(opts, arg).run
    end
  end
end
