#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "resolv"
require "uri"

class IPInfo
  def initialize(hostn, recurse: true)
    @host = hostn
    @recurse = recurse
    $stdout.puts("info for #{@host.dump}:")
  end

  def output(title, &block)
    $stdout.puts("  #{title}:")
    block.call
    $stdout.puts
  end

  def shell_command(*cmd, &block)
    IO.popen(cmd).each_line do |ln|
      block.call(ln.strip)
    end
  end

  def command_exists(commandname)
    ENV["PATH"].split(":").each do |path|
      [commandname, commandname + ".exe"].each do |com|
        com = File.join(path, com)
        #p [:com, com]
        if File.executable?(com) then
          return true
        end
      end
    end
    return false
  end

  def generic_exec_command(commandname, args, check_command: true)
    if (check_command && command_exists(commandname)) || true then
      shell_command(*[commandname, *args]) do |ln|
        printf("    %s\n", ln)
        if block_given? then
          yield ln
        end
      end
    else
      $stderr.puts("err: command #{commandname.dump} not found in your $PATH")
    end
  end

  def exec_host(hs, check_cmd)
    additional = []
    generic_exec_command("host", hs, check_command: check_cmd) do |line|
      if @recurse then
        # this will probably(?) only apply to hostnames, but not
        # to ip addresses, so probably unlikely to run into a
        # loop here... i hope?
        match = line.match(/.+? has address (.*)/)
        if match then
          addr = match[1].strip
          if not additional.include?(addr) then
            additional.push(addr)
          end
        end
      end
    end
    additional.each do |addr|
      exec_host(addr, false)
    end
  end

  def exec_geoip(hs)
    generic_exec_command("geoiplookup", [hs])
  end

  def do_geoip
    output("GeoIP Information") do
      exec_geoip(@host)
    end
  end

  def do_host
    output("Host Information") do
      exec_host(@host, nil)
    end
  end
end

def convert_possible_url(str)
  # technically, this could be done with URI,
  # but ruby's stdlib URI parser is kind-of, sort-of wonkey
  rx = /^https?:\/\//
  if str.match(rx) then
    $stderr.puts("input looks like an URL, converting ...")
    begin
      return URI.parse(str).hostname
    rescue => ex
      $stderr.printf("convert_possible_url: URI.parse error: (%s) %s\n", ex.class, ex.message)
      return convert_possible_url(str.gsub(rx, ''))
    end
  end
  # replace backslashes (if any),
  # then split by /, get the host, and discard the rest
  return str.gsub(/\\/, '/').split(/\//)[0]
end

def handle(arg, commands, options)
  arg = convert_possible_url(arg)
  info = IPInfo.new(arg)
  # ha-ha, i'm using reflection lazily.
  commands.each do |name, doit|
    if doit then
      begin
        info.send(name)
      #rescue NoMethodError => err
        #$stderr.puts("err: sorry, but #{name} is not yet implemented. :-(")
      end
    end
  end
end

def processfiles(argv, commands, options)
  ips = []
  argv.each do |arg|
    File.foreach(arg) do |line|
      line.strip!
      next if line.empty?
      next if line.match(/^#/)
      handle(arg, commands, options)
    end
  end
end

begin
  commands= {
    do_host: true,
    do_geoip: true,
    do_whois: false,
    do_dig: false,
    do_nmap: false,
  }
  options = OpenStruct.new({
    filelisting: false,
  })
  prs = OptionParser.new {|prs|
    prs.on(nil, "--[no-]geoip", "enable or disable geoiplookup (very fast)"){|v|
      commands[:do_geoip] = v
    }
    prs.on(nil, "--[no-]host", "enable or disable host lookup (fast)"){|v|
      commands[:do_host] = v
    }
    prs.on("-w", "--[no-]whois", "perform a whois lookup (slow-ish)"){|v|
      commands[:do_whois] = v
    }
    prs.on("-d", "--[no-]dig", "perform a lookup with dig (quite slow)"){|v|
      commands[:do_dig] = v
    }
    prs.on("-n", "--[no-]nmap", "search for open ports (VERY SLOW)"){|v|
      commands[:do_nmap] = v
    }
    prs.on("-f", "--fileinput", "arguments passed to ipinfo are files containing IPs/hosts"){|_|
      options.filelisting = true
    }
  }
  prs.parse!
  if ARGV.empty? then
    puts prs.help
  else
    if options.filelisting then
      processfiles(ARGV, commands, options)
    else
      ARGV.each do |arg|
        handle(arg, commands, options)
      end
    end
  end
end
