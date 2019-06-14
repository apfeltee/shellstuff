#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "open3"
#require "awesome_print"

CommandInfo = Struct.new(:titlestr, :command, :fileonly)

WMIC_EXE = "C:/Windows/System32/wbem/WMIC.exe"

OTHERCOMMANDS = {
  "size" => CommandInfo.new("Size", ["du", "-h", nil], true),
  "md5"  => CommandInfo.new("MD5", ["md5sum"], true),
}

def rcmd(*cmd, &block)
  Open3.popen3(*cmd) do |stdin, stdout, stderr, thread|
    block.call(stdin, stdout, stderr, thread)
  end
end

def makewinpath(path)
  rcmd("cygpath", "-wa", path) do |stdin, stdout, stderr, th|
    return stdout.read.strip
  end
end


module Commands
  class BaseCommand
    def initialize(inputfile)
      @inputfile = inputfile
      @command = []
    end
  end

  class CMD_WMICDump
  end
end

def runwmic(path, opts)
  dict = {}
  shcmd = [WMIC_EXE, "datafile", "where", sprintf("name=%p", path), "get", "/value"]
  rcmd(*shcmd) do |stdin, stdout, stderr, th|
    th.join
    err = stderr.read.strip
    if err.length > 0 then
      warn("wmic failed: #{err.strip.dump}")
      exit 1
    end
    ret = {}
    raw = stdout.read.strip
    raw.split(/\r\r\n/).each do |part|
      part.strip!
      if part.length > 0 then
        if((m = part.match(/(\w+)=(.+)/)) != nil) then
          if ((name = m[1]) != nil) && ((value = m[2]) != nil) then
            if (opts.wantedkeys.length > 0) && (not opts.wantedkeys.include?(name.downcase)) then
              next
            end
            dict[name] = value
          end
        end
      end
    end
  end
  return dict
end

begin
  opts = OpenStruct.new({
    wantedkeys: [],
  })
  OptionParser.new{|prs|
    prs.on("-k<key>", "--key=<key>", "print only <key> (can be used multiple times)"){|str|
      str.strip.split(",").each do |v|
        opts.wantedkeys.push(v.strip.downcase)
      end
    }
  }.parse!
  if ARGV.length > 0 then
    ARGV.each do |arg|
      if File.exist?(arg) then
        winpath = makewinpath(arg)
        $stderr.printf("wmic info for %p:\n", winpath)
        runwmic(winpath, opts).each do |k, v|
          printf("   %20s: %p\n", k, v)
        end
      else
        puts "path #{arg.inspect} does not exist"
      end
    end
  else
    puts "usage: #$0 <file> [<another-file> ...]"
  end
end
