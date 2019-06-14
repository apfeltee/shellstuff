#!/usr/bin/ruby

require "optparse"

HostInfo = Struct.new(:host, :aliases)

HOSTS = [
  HostInfo.new("whois.crsnic.net", ["crsnic", "crs"]),
  HostInfo.new("geektools.com", ["geektools", "gt", "geek"]),
]

DEFAULT_HOST = HOSTS.first
DEFAULT_QUERY_TEMPLATE = "domain %s"

def gethost(s)
  s.downcase!
  HOSTS.each do |h|
    if (h.host == s) || (h.aliases.include?(s)) then
      return h.host
    end
  end
  if s.include?(".") then
    $stderr.printf("WARNING: host %p may not be supported!\n", s)
    return s
  end
  $stderr.printf("ERROR: host %p does not look like a valid address\n", s)
  exit(1)
end

def do_whois(host, querytpl, subject)
  query = sprintf(querytpl, subject)
  cmd = ["whois"]
  if host != nil then
    cmd.push("-h", host)
  end
  cmd.push(query)
  if system(*cmd) then
    return 0
  end
  return 1
end

begin
  rc = 0
  host = DEFAULT_HOST.host
  querytpl = DEFAULT_QUERY_TEMPLATE
  OptionParser.new{|prs|
    prs.on("-x<s>", "--query=<s>", "set query template (defaults to #{DEFAULT_QUERY_TEMPLATE.dump})"){|s|
      querytpl = s
    }
    prs.on("-t<name>", "--use=<name>", "select whois host to query, or use '-' to use system default"){|s|
      if s == "-" then
        host = nil
      else
        host = gethost(s)
      end
    }
    prs.on("-l", "-L", "--list", "list supported hosts"){|_|
      $stdout.printf("%-25s %s\n%s\n", "Host", "Aliases", ("-" * 50))
      HOSTS.each do |h|
        $stdout.printf("%-25s %s\n", h.host, h.aliases.join(", "))
      end
      exit(1)
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("need a hostname or IP address\n")
  else
    ARGV.each do |a|
      rc += do_whois(host, querytpl, a)
    end
  end
  exit(rc)
end
