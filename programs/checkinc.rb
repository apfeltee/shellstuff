#!/usr/bin/ruby

# wrapper around iwyu, since iwyu can't figure out where system headers are.

require "ostruct"
require "optparse"

INCDIRS = %w(
 /usr/include/c++/10
 /usr/include/x86_64-linux-gnu/c++/10
 /usr/include/c++/10/backward
 /usr/lib/gcc/x86_64-linux-gnu/10/include
 /usr/local/include
 /usr/include/x86_64-linux-gnu

 /usr/lib/gcc/x86_64-linux-gnu/11/include
 /usr/local/include
 /usr/include/x86_64-linux-gnu
 /usr/include
)

def run_iwyu(opts, files, extracmd)
  cmd = ["iwyu", *extracmd]
  if opts.language then
    cmd.push("-x#{opts.language}")
  end
  if opts.stdlang then
    cmd.push("-std=#{opts.stdlang}")
  end
  INCDIRS.each do |id|
    cmd.push("-I#{id}")
  end
  opts.includes.each do |d|
    cmd.push("-I#{d}")
  end
  cmd.push(*files)
  exec(*cmd)
end

begin
  extra = []
  setlang = false
  opts = OpenStruct.new({
    language: "c++",
    stdlang: "c++2a",
    includes: [],
  })
  OptionParser.new{|prs|
    prs.on("-x<lang>"){|v|
      opts.language = v
    }
    prs.on("-s<std>", "--std=<std>"){|v|
      opts.stdlang = v
      setlang = true
    }
    prs.on("-I<path>"){|v|
      opts.includes.push(v)
    }
    prs.on("-i"){
      extra.push("-i")
    }
  }.parse!
  if (opts.language == "c") && opts.stdlang.match?(/c\+\+/) then
    opts.stdlang = nil
  end
  if ARGV.empty? then
    $stderr.printf("too few arguments\n")
  end
  if setlang == false then
    iscpp = false
    ARGV.each do |a|
      if a.match?(/\.(cc|cpp|cxx|c\+\+)$/i) then
        iscpp = true
        break
      end
    end
    if iscpp == false then
      opts.language = 'c'
      opts.stdlang = nil
    end
  end
  run_iwyu(opts, ARGV, extra)
end

