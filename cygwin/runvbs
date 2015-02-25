#!/usr/bin/ruby

require 'pp'

@debug = false

def dbg(*args)
  if @debug then
    $stderr.print("runvbs:debug: ")
    $stderr.puts(*args)
  end
end

def shcmd(*args)
  cmdstr = args.join(" ")
  dbg("fn:shcmd: %x[#{cmdstr}]")
  return %x[#{cmdstr}]
end

def shexec(*args)
  dbg("fn:shexec: system(*#{args.inspect})")
  system(*args)
end

def which(com)
  dbg("fn:which: com=#{com.inspect}")
  file = shcmd("which", com).strip
  if not File.file? file then
    raise Exception, "command '#{com}' does not exist? (returned $file: #{file})"
  end
  return file
end

def cygpath(path)
  return shcmd("cygpath", "-wa", path).strip
end


def parse_options(argv)
  startidx = 0
  endidx = argv.length
  ret =
  {
    schost: "cscript",
  }
  argv.each do |arg|
    case arg
      when /-(.*)/
        dbg("parse_options: checking for flags")
        case arg
          when "-w"
            ret[:schost] = "wscript"
            dbg("parse_options: using wscript for schost")
          when "-c"
            ret[:schost] = "cscript"
            dbg("parse_options: using cscript for schost")
          when "-d"
            @debug = true
          else
            raise Exception, "bad option '#{arg}'"
        end
        startidx += 1
    end
  end
  real_argv = argv[startidx, endidx]
  ret[:script] = cygpath(which(real_argv[0]))
  ret[:args] = real_argv[1, real_argv.length]
  return ret
end

if ARGV.length != 0 then
  opts = parse_options(ARGV)
  dbg("main: opts=#{opts}")
  shexec("cmd", "/c", opts[:schost], opts[:script], *opts[:args])
end
