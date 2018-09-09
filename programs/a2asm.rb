#!/usr/bin/ruby --disable-gems

require "optparse"
require "open3"

=begin
usage: ndisasm [-a] [-i] [-h] [-r] [-u] [-b bits] [-o origin] [-s sync...]
               [-e bytes] [-k start,bytes] [-p vendor] file
   -a or -i activates auto (intelligent) sync
   -u same as -b 32
   -b 16, -b 32 or -b 64 sets the processor mode
   -h displays this text
   -r or -v displays the version number
   -e skips <bytes> bytes of header
   -k avoids disassembling <bytes> bytes from position <start>
   -p selects the preferred vendor instruction set (intel, amd, cyrix, idt)
=end
def opts2flags(opts)
  r = []
  opts.each do |k, val|
    case k
      when :cpumode then
        r.push("-b", val)
      when :autosync then
        if val then
          r.push("-a")
        end
      when :skipbytes then
        r.push("-e", val)
      when :avoidpos then
        r.push("-k", val)
      when :vendor then
        r.push("-p", val)
      else
        raise "option #{k.inspect} (value: #{val.inspect}) is not supported"
    end
  end
  return r.map(&:to_s)
end

def file2asm(filepath, opts, &block)
  flags = opts2flags(opts)
  Open3.popen3("ndisasm", *flags, filepath) do |stdin, stdout, stderr, thread|
    begin
      while true
        line = stdout.readline.strip
        next if line.match(/^-\h+?$/)
        #$stderr.printf("rawline: %p\n", line);
        if parts = line.match(/(........) (.+?) (.*)/) then
          id = parts[1].strip
          tab = parts[2].strip
          asm = parts[3].strip
          block.call(asm)
        else
          raise "regex match error for #{line.dump}"
        end
      end
    rescue EOFError
      $stderr.puts("done")
    end
  end
end


begin
  $stdout.sync = true
  ofile = $stdout
  haveofile = false
  opts = {
    autosync: true,
    cpumode: 32,
    vendor: "intel",
  }
  prs = OptionParser.new{|prs|
    prs.on("-v<vendor>", "--vendor=<vendor>", "select <vendor> as instruction set"){|v|
      opts[:vendor] = v
    }
    prs.on("-b<bits>", "--cpu=<bits>", "use <bits> as cpu mode (e.g., 16, 32, 64. default is 32)"){|v|
      opts[:cpumode] = v
    }
    prs.on("-o<file>", "--out=<file>", "write output to <file> instead of stdout"){|v|
      ofile = File.open(v, "wb")
      haveofile = true
    }
  }
  outputter = lambda{|str|
    ofile.puts(str)
  }
  prs.parse!
  begin
    if ARGV.empty? then
      if not $stdin.tty? then
        file2asm("-", opts, &outputter)
      else
        puts(prs.help)
      end
    else
      file = ARGV.shift
      file2asm(file, opts, &outputter)
    end
  ensure
    if haveofile then
      ofile.close
    end
  end
end
