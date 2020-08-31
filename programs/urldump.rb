#!/usr/bin/ruby

#require "uri"
require "cgi"
#require "pp"
require "ostruct"
require "optparse"
#require "json"
#require "awesome_print"
require "yaml"
begin
  require "addressable/uri"
rescue LoadError
end

module Utils
  DEFAULT_ENCODING = "UTF-8"

  def self.old_url_unescape(string, encoding: DEFAULT_ENCODING, force: false)
    #$stderr.printf("Utils.url_unescape(%p, encoding: %p, force: %p)\n", string, encoding, force)
    str = string.scrub.tr('+', ' ').b.gsub(/((?:%[0-9a-fA-F]{2})+)/){|m|
      [m.delete('%')].pack('H*')
    }.force_encoding(encoding)
    rt = (
      if str.valid_encoding? then
        str
      else
        str.force_encoding(string.encoding)
      end
    )
    if force == true then
      if rt.match?(/\%[A-Z0-9]{2}/) then
        return old_url_unescape(rt, encoding: encoding, force: force)
      end
    end
    return rt
  end

  def self.url_unescape(str, **ignoredkw, &b)
    buf = []
    i = 0
    len = str.length
    while (i < len) do
      ch = str[i]
      if (ch == "%") && (str[i-1] != "%") then
        first = str[i+1]
        sec = str[i+2]
        if (first != nil) && (sec != nil) then
          tmp = [first, sec]
          #$stderr.printf("tmp = %p\n", tmp)
          n = tmp.join.to_i(16).chr
          if block_given? then
            yield n
          else
            buf.push(n)
          end
        end
        i += 2
      else
        buf.push(ch)
      end
      i += 1
    end
    return nil if block_given?
    return buf.join
  end

  def self.parse_query(str, encoding: DEFAULT_ENCODING, forcedecode: false)
    ret = {}
    cdec = lambda{|s|
      #$stderr.printf("url_unescape(%p, encoding: %p, force: %p)\n", s, encoding, forcedecode)
      url_unescape(s, encoding: encoding, force: forcedecode)
    }
    if not str.nil? then
      CGI.parse(str).each do |vkey, vval|
        realval = nil
        if vval.is_a?(Array) && (vval.length > 1) then
          #realval = vval.map(&CGI.method(:unescape))
          realval = vval.map{|s| cdec.call(s) }
        elsif vval.is_a?(Hash) then
          #realval = vval.map{|k, v| [k, CGI.unescape(v.to_s) ] }.to_h
          realval = vval.map{|k, v| [k, cdec.call(v.to_s) ] }.to_h
        else
          if vval[0] != nil then
            realval = cdec.call(vval[0])
          end
        end
        #if realval != nil then
          ret[vkey.to_s] = realval
        #end
      end
    end
    return ret
  end
end

module Printers
  extend self

  def normal(out, data)
    data.each do |name, value|
      out.printf("%-10s =>  ", name)
      if name == "query" then
        if value.length > 0 then
          out.puts("{")
          value.each { |qn, qv|
            out.printf("  %p = ", qn)
            if qv.is_a?(Array) then
              out.print("[\n", qv.map{|v| sprintf("    %p", v)}.join(",\n"), "\n  ]")
            else
              out.printf("%p", qv)
            end
            out.printf("\n")
          }
          out.puts("}")
        else
          out.puts("{}")
        end
      else
        out.printf("%p", value)
      end
      out.puts
    end
  end

  if defined?(JSON) then
    def json(out, data)
      out.puts(JSON.pretty_generate(data))
    end
  end

  if defined?(AwesomePrint) then
    def awesome(out, data)
      out.puts(data.awesome_inspect)
    end
  end

  if defined?(YAML) then
    def yaml(out, data)
      out.puts(YAML.dump(data, canonical: false, header: true))
    end
  end
end

# this function is NOT necessary if addressable is available!
def rewrite(url)
  if not url.match(/^\w+:\/\//) then
    # this addresses things like "abp:subscribe?blah=..." urls, i.e.,
    # urls with a proto but no slashes
    proto, *rest = url.split(":")
    nurl = sprintf("%s://%s", proto, rest.join(":"))
    return nurl
  end
  return url
end

def parse_uri(str)
  if defined?(Addressable) then
    return Addressable::URI.parse(str)
  else
    return URI.parse(rewrite(str))
  end
end


def urldump(str, options)
  url = parse_uri(str)
  data = Hash({
    "scheme"   => url.scheme,
    "userinfo" => url.userinfo,
    "hostname" => url.hostname,
    "port"     => url.port,
    "path"     => url.path,
    "fragment" => url.fragment,
    "query"    => Utils.parse_query(url.query, forcedecode: options.forcedecode),
  }).select{|k, v| not v.nil?}.to_h
  if options.forcedecode then
    data = data.map{|k, v|
      if v.is_a?(String) then
        [k, Utils.url_unescape(v, force: options.forcedecode)]
      else
        [k, v]
      end
     }.to_h
  end
  if options.wanted.empty? then
    Printers.send(options.printer, $stdout, data)
  else
    if options.wanted.length > 1 then
      options.wanted.each_with_index do |w, i|
        v = data[w]
        if v then
          $stdout.printf("%s=%p", w, v)
          if ((i + 1) != options.wanted.length) then
            $stdout.write(" ")
          end
        end
      end
    else
      v = data[options.wanted.first]
      $stdout.puts(v) unless v.nil?
    end
  end
end

begin
  wants = %w(port hostname path query scheme user password)
  options = OpenStruct.new({
    forcedecode: false,
    printer: "normal",
    wanted: [],
  })
  prs = OptionParser.new {|prs|
    prs.on("-p<name>", "--print-as=<name>", "Use <name> as output type"){|name|
      options.printer = name
      if not Printers.respond_to?(options.printer.to_sym) then
        $stderr.puts("error: output type #{name.dump} is unknown")
        exit
      end
    }
    prs.on("-f", "--forcedecode", "force URL decoding of strings until no longer URL decoded (warning: may break output!)"){
      options.forcedecode = true
    }
    #prs.on("-p", "--port", "print port, if any"){|_|
    #  options.wanted.push(:port)
    #}
    #prs.on("-h", "--hostname", "print hostname, if any")
    wants.each do |w|
      prs.on(nil, "--#{w}", "print #{w}, if any"){|_|
        options.wanted.push(w)
      }
    end
  }
  prs.parse!
  if ARGV.empty? then
    if not $stdin.tty? then
      $stdin.each_line do |line|
        urldump(line.strip, options)
      end
    else
      $stderr.puts(prs)
    end
  else
    ARGV.each do |arg|
      urldump(arg, options)
    end
  end
end
