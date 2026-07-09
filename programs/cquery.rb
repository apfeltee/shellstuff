#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "tempfile"

CLANG_QUERY_EXE = "clang-query"

DEFAULT_COMMANDS = [
  "set traversal     IgnoreUnlessSpelledInSource",
  "set bind-root     true",
  # ^ true unless you use any .bind("foo") commands
  "set print-matcher true",
  "enable output     dump",
]

class CQueryWrap
  def initialize(opts)
    @opts = opts
    @cmd = [CLANG_QUERY_EXE]
    incpaths = find_include_paths()
    @commandfile = Tempfile.new('cquerycommands')
    DEFAULT_COMMANDS.each do |c|
      @commandfile.puts(c)
    end
    @commandfile.close
    $stderr.printf("tmpfile: %p %p\n", @commandfile.path, File.stat(@commandfile.path))
    @cmd.push(sprintf("--preload=%s", @commandfile.path))
    incpaths.each do |path|
      add_cflag("-I"+path)
    end
  end

  def cleanup
    $stderr.printf("cleanup ....\n")
    @commandfile.unlink
  end

  def find_include_paths
    return [
      "/usr/include/c++/10",
      "/usr/include/x86_64-linux-gnu/c++/10",
      "/usr/include/c++/10/backward",
      "/usr/lib/gcc/x86_64-linux-gnu/10/include",
      "/usr/local/include",
      "/usr/include/x86_64-linux-gnu",
      "/usr/include",
    ]
  end

  def add_cflag(flag)
    @cmd.push(sprintf("--extra-arg-before=%s", flag))
  end

  def add_command(cmd)
    @cmd.push("-c", cmd)
  end

  def run(argv)
    if @opts.inlang != nil then
      add_cflag("-x" + @opts.inlang)
    end
    if @opts.cppstd != nil then
      add_cflag("-std=" + @opts.cppstd)
    end
    fullcmd = [*@cmd, *argv]
    $stderr.printf("cmd: %p\n", fullcmd)
    system(*fullcmd)
  end

end

begin
  opts = OpenStruct.new({
    inlang: "c++",
    cppstd: "c++20",
  })
  OptionParser.new{|prs|
    prs.on("-x<mode>", "set language (defaults to C++)"){|v|
      opts.inlang = v
    }
  }.parse!
  cq = CQueryWrap.new(opts);
  begin
    cq.run(ARGV)
  ensure
    cq.cleanup
  end
end

