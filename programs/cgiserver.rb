#!/usr/bin/env ruby

require "ostruct"
require "optparse"
require "pry-byebug"
require "webrick"
include WEBrick

DEFAULT_PORT = 8080
DEFAULT_WEBROOT = Dir.pwd

module Servlet
  class BasicServlet < WEBrick::HTTPServlet::AbstractServlet
    def initialize(cgiserver)
      @cgiserver = cgiserver
      @webrick = nil
    end

    def get_instance(webrick)
      @webrick = webrick
      return self
    end
  end

  class AdminPage < BasicServlet
    def do_GET(request, response)
      if (a = request.query["a"]) && (b = request.query["b"]) then
        response.status = 200
        response.content_type = "text/plain"
        result = nil
        case request.path
          when "/add"
            result = MyNormalClass.add(a, b)
          when "/subtract"
            result = MyNormalClass.subtract(a, b)
          else
            result = "No such method"
        end
        response.body = result.to_s + "\n"
      else
        response.status = 200
        response.body = "You did not provide the correct parameters"
      end
    end
  end

end

class CGIServer
  def initialize(opts)
    ENV['ENVIRONMENT'] = 'development'
    @opts = opts
    cert_name = [
      %w[CN localhost],
    ]
    wb = File.absolute_path(@opts.webroot)
    params = {
      Port: @opts.port,
      DocumentRoot: wb,
    }
    if @opts.localhostssl then
      params[:SSLEnable] = true
      params[:SSLCertName] = cert_name
    end
    @srv = HTTPServer.new(**params)
    msg("mounting %p as web root", wb)
    @srv.mount("/", HTTPServlet::FileHandler, wb, FancyIndexing: true)
    mount_servlet("/__admin", Servlet::AdminPage)
  end

  def mount_path(path, &b)
    @srv.mount_proc('/') do |req, res|
      b.call(req, res)
    end
  end

  def mount_servlet(path, klass)
    kinstance = klass.new(self)
    @srv.mount(path, kinstance)
  end

  def msg(fmt, *a)
     @srv.logger.log(0, sprintf(fmt, *a))
  end

  def launch
    msg("starting server, port: %d", @opts.port)
    @srv.start
  end

  def shutdown
    @srv.shutdown
  end
end

def main(opts)
=begin
  Dir.glob("**/*") do |file|
    next if File.directory?(file)
    next if not file.scrub.match?(/\.cgi$/i)
    fpa = File.expand_path(file)
    puts("mounting CGI %p at /%s" fpa, fpa)
    s.mount("/#{file}", HTTPServlet::CGIHandler, File.expand_path(file))
  end
=end
  csrv = CGIServer.new(opts)
  trap("INT") do
    $stderr.printf("received ^C, goodbye\n")
    csrv.shutdown
  end
  csrv.launch
end

begin
  opts = OpenStruct.new({
    port: DEFAULT_PORT,
    webroot: DEFAULT_WEBROOT,
    localhostssl: false,
  })
  OptionParser.new{|prs|
    prs.on("-p<port>", "--port=<port>", "set port (default: #{DEFAULT_PORT})"){|v|
      opts.port = v.to_i
    }
    prs.on("-s", "--ssl", "enable SSL for localhost"){
      opts.localhostssl = true
    }
  }.parse!
  if ARGV.length > 0 then
    opts.webroot = ARGV.first
    if not File.directory?(opts.webroot) then
      $stderr.printf("specified web root %p is not a directory\n", opts.webroot)
      exit(1)
    elsif not File.readable?(opts.webroot) then
      $stderr.printf("specified web root %p is not readable\n", opts.webroot)
      exit(1)
    end
  end
  main(opts)
end
