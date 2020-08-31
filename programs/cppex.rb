#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "shellwords"

COMPILERMACROS = [
  # "restrict" is obscure enough to not even be supported by many compilers...
  "restrict=",
  "__unaligned",
  "__inline__=",
  "__inline=",
  "__cdecl=",
  "__int64=int64_t",
  "__attribute__(...)=",
  "__declspec(...)=",
  "__builtin_va_start=va_start",
  "__builtin_va_end=va_end",
  "__builtin_va_list=va_list",
  "__gnuc_va_list=va_list",
]

AUTOHEADERS = [
  "stdarg.h",
  "stddef.h",
  "stdint.h",
]

def cppex(opts, files)
  out = opts.outputhandle
  stripws = opts.stripwhitespace
  comp = opts.compiler.shellsplit
  cmd = [*comp, "-E", "-P", "-x", opts.language]
  if opts.std then
    cmd.push("-std=#{opts.std}")
  end
  if opts.removemacros then
    COMPILERMACROS.each do |cm|
      cmd.push("-D#{cm}")
    end
  end
  cmd.push("-")
  IO.popen(cmd, "r+") do |pipe|
    opts.systemincludes.each do |inc|
      pipe.printf("#include <%s>\n", inc)
    end
    opts.localincludes.each do |inc|
      pipe.printf("#include \x22%s\x22\n", inc)
    end
    files.each do |f|
      File.open(f, "rb") do |fh|
        pipe.write(fh.read)
        pipe.puts
        pipe.flush
      end
    end
    pipe.puts
    pipe.flush
    # pipe must be closed before reading
    pipe.close_write
    if opts.autoheaders != nil then
      # this is NOT passed to clang-format!
      (AUTOHEADERS | opts.autoheaders).each do |h|
        out.printf("#include <%s>\n", h)
      end
    end
    if opts.clangformat then
      IO.popen("clang-format", "r+") do |cfpipe|
        cfpipe.write(pipe.read)
        cfpipe.close_write
        out.write(cfpipe.read)
      end
    else
      pipe.each_line do |line|
        if stripws then
          line.rstrip!
          if not line.empty? then
            out.puts(line)
          end
        else
          out.write(line)
        end
      end
    end
    out.flush
 end
end

begin
  opts = OpenStruct.new({
    compiler: "gcc",
    language: "c",
    removemacros: false,
    stripwhitespace: false,
    clangformat: false,
    systemincludes: [],
    localincludes: [],
    autoheaders: nil
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help, and exit"){
      $stderr.puts(prs.help)
      exit(1)
    }
    prs.on("-o<file>", "--out=<file>", "write output to <file>"){|s|
      opts.outputfile = s
    }
    prs.on("-e<s>", "--compiler=<s>", "set compiler (e.g., g++, clang, tcc, etc)"){|e|
      opts.compiler = e
    }
    prs.on("-i<file>", "--include=<file>", "add system #include"){|f|
      opts.systemincludes.push(f)
    }
    prs.on("-l<file>", "--localinclude=<file>", "add local #include"){|f|
      opts.localincludes.push(f)
    }
    prs.on("-c<std>", "--std=<s>", "set language standard (check your compiler docs)"){|s|
      opts.std = s
    }
    prs.on("-x<lang>", "--lang=<lang>", "set input language (e.g., 'c++' for C++, etc)"){|l|
      opts.language = l
    }
    prs.on("-r", "--nocompilermacros", "remove compiler macros (e.g., __attribute__, etc)"){
      opts.removemacros = true
    }
    prs.on("-a[<file>]", "--autoheader[=<file>]", "add #includes for #{AUTOHEADERS.join(", ")}"){|s|
      if opts.autoheaders == nil then
        opts.autoheaders = []
      end
      if s != nil then
        opts.autoheaders.push(s)
      end
    }
    prs.on("-s", "--strip", "strip whitespace from output"){
      opts.stripwhitespace = true
    }
    prs.on("-f", "--clangformat", "feed output to clang-format"){
      opts.clangformat = true
    }
  }.parse!
  if opts.systemincludes.empty? && opts.localincludes.empty? then
    $stderr.printf("no includes specified. try cppex -h\n")
    exit(1)
  else
    opts.outputhandle = $stdout
    if opts.outputfile then
      opts.outputhandle = File.open(opts.outputfile, "wb")
    end
    files = []
    begin
      ARGV.each do |a|
        if File.file?(a) then
          if File.readable?(a) then
            files.push(a)
          else
            $stderr.printf("cppex: not a readable file: %p\n", a)
          end
        else
          $stderr.printf("cppex: not a file: %p\n")
        end
      end
      cppex(opts, files)
    ensure
      if opts.outputfile then 
        opts.outputhandle.close
      end
    end
  end
end



