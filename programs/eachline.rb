#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "shellwords"
require "readline"

DEFAULT_OPTIONS = OpenStruct.new({
  maxslice: 15,
  prompt: "press enter to continue, 'next' to skip, 'q', 'quit', or 'exit' to quit: ",
  separator: "\n",
  command: "",
  errorcontinue: false,
})


class EachLine
  def initialize(opts)
    @opts = opts
  end

  def prompt()
    rs = Readline.readline(@opts.prompt)
    if rs == nil then
      $stderr.puts("^D received?")
      exit(1)
    end
    if rs.match?(/^(exit|q(uit)?|stop)/i) then
      exit()
    elsif rs.match?(/^n(e(x(t)?)?)?/i) then
      return false
    end
    return true
  end

  def mkcmd(item)
    if @opts.command.match?(/%\w/) then
      return sprintf(@opts.command, item.shellescape)
    end
    return (@opts.command + " " + item.to_s.shellescape)
  end

  def run(item)
    cmd = mkcmd(item)
    if not system(cmd) then
      if not @opts.errorcontinue then
        $stderr.printf("command %p failed, stopping\n", cmd)
        exit(1)
      end
    end
  end

  def do_lines(lines)
    lines.each_slice(@opts.maxslice) do |slice|
      $stdout.printf("items in queue:\n")
      slice.each.with_index do |item, i|
        $stdout.printf("  %-3d %p\n", i, item)
      end
      next if not prompt()
      puts("okay, opening next slice")
      slice.each do |item|
        run(item)
      end
    end
  end

  def do_io(hnd)
    do_lines(hnd.readlines(@opts.separator).map(&:strip).reject(&:empty?))
  end

  def do_file(file)
    File.open(file, "rb") do |fh|
      do_io(fh)
    end
  end
end

def defval(key, fmt, str)
  dv = DEFAULT_OPTIONS[key]
  return sprintf("%s (default: #{fmt})", str, dv)
end

begin
  opts = DEFAULT_OPTIONS.dup
  OptionParser.new{|prs|
    prs.on("-n<d>", "--slice=<d>", defval(:maxslice, "%s", "how big each slice should be ")){|v|
      opts.maxslice = v.to_i
    }
    prs.on("-p<str>", "--prompt", defval(:prompt, "%p", "specify input prompt")){|s|
      opts.prompt = s
    }
    prs.on("-c<str>", "--command=<str>", "specify command to run"){|s|
      opts.command = s.strip
    }
    prs.on("-f", "-i", "--continue", defval(:errorcontinue, "%p", "continue on errors")){
      opts.errorcontinue = true
    }
  }.parse!
  if opts.command.empty? then
    $stderr.printf("error: no command specified\n")
    exit(1)
  end
  el = EachLine.new(opts)
  if ARGV.empty? then
    if $stdin.tty? then
      $stderr.printf("error: no files provided, and nothing piped\n")
      exit(1)
    else
      el.do_io($stdin)
    end
  else
    ARGV.each do |file|
      el.do_file(file)
    end
  end
end

