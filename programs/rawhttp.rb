#!/usr/bin/ruby

# this is basically just a (arguably) slightly more sophisticated
# version of doing http with netcat.

require "ostruct"
require "optparse"
require "socket"
require "addressable/uri"


class RawHTTP
  def initialize(opts, host, port)
    @host = host
    @port = port
    @sock = TCPSocket.open(host, port)
    @sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
  end

  def cleanup
    @sock.close
  end

  def tosock(str)
    $stderr.printf("writing to socket:\n")
    str.each_line do |ln|
      $stderr.printf("   %s\n", ln.dump[1 .. -2])
    end
    return @sock.write(str)
  end

  def mk_head(com, path, httpver, fields)
    buf = [com.upcase, " ", Addressable::URI.escape(path), " ", "HTTP/", httpver, "\r\n"]
    fields.each do |k, v|
      buf.push(k, ": ", v, "\r\n")
    end
    buf.push("\r\n")
    return buf.join
  end

  def sendreceive(com, path, httpver, fields, &recv)
    httpfields = { "Host" => @host }
    httpfields.merge!(fields)
    msg = mk_head(com, path, httpver, httpfields)
    blen = msg.length
    tosock(msg)
    $stderr.printf("data sent... now reading response:\n")
    @sock.close_write
    while (chunk = @sock.gets) != nil do
      #$stderr.printf("chunk: %p\n", chunk)
      recv.call(chunk)
    end
  end
end

def parse_url(url)
  uri = Addressable::URI.parse(url)
  if (uri.path == nil) || (uri.path == "") then
    uri.path = "/"
  end
  return uri
end

def do_rawhttp(opts, url)
  uri = parse_url(url)
  upath = (opts.urlpath || uri.path)
  meth = (opts.httpmethod || "GET")
  httpver = (opts.httpversion || "1.1")
  port = (uri.port || 80)
  if uri.scheme == "https" then
    $stderr.printf("*** HTTPS will likely not work. you've been warned!***\n")
    port = 443
  end
  if uri.query then
    upath += "?" + uri.query
  end
  ht = RawHTTP.new(opts, uri.hostname, port)
  begin
    endofheaders = false
    ht.sendreceive(meth, upath, httpver, opts.headers) do |chunk|
      if endofheaders && opts.ignorebody then
        break
      end
      $stdout.write(chunk)
      if chunk == "\r\n" then
        endofheaders = true
      end
      $stdout.flush
    end
  ensure
    ht.cleanup
  end
end

begin
  opts = OpenStruct.new({ 
    urlpath: nil,
    headers: {},
    httpmethod: nil,
    httpversion: nil,
  
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit()
    }
    prs.on("-f<line>", "--header=<line>"){|v|
      parts = v.split(":")
      if parts.length == 1 then
        $stderr.printf("expected argument to '-f' to be like 'fieldname: fieldvalue' (i.e., -f 'X-My-Stuff: Blah')")
        exit(1)
      end
      key = parts.shift
      rest = parts.join(":")
      opts.headers[key] = rest
    }
    prs.on("-p<path>", "--path=<path>", "explicitly set crafted path"){|v|
      opts.urlpath = v
    }
    prs.on("-m<method>", "--method=<method>", "explicitly set crafted method (stg else than GET/POST... you get the idea)"){|v|
      opts.httpmethod = v
    }
    prs.on("-0", "-n", "--nobody", "ignore body entirely"){
      opts.ignorebody = true
    }
    prs.on("-2", "--http2"){
      opts.httpversion = "2.0"
    }
    prs.on("-x<s>"){|v|
      m = v.scrub.match(/(?<header>[\w\-\_]+)=(?<size>.*)/)
      if m == nil then
        $stderr.printf("bad format to '-x'\n")
        exit(1)
      end
      h = m["header"]
      cnt = m["size"]
      str = "#"
      tmp = cnt.split(":")
      if tmp.length > 1 then
        str = tmp.shift
      end
      cnt = tmp.shift.to_i
      opts.headers[h] = (str * cnt)
    }
  }.parse!
  urlarg = ARGV.shift
  if urlarg == nil then
    $stderr.printf("no urls given\n")
    exit(1)
  else
    urlarg.scrub!
    if not urlarg.match?(/^https?:/) then
      urlarg = ("http://" + urlarg)
    end
    do_rawhttp(opts, urlarg)
  end
end
