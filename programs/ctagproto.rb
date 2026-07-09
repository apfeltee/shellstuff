#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "oj"

=begin
ctags --list-kinds-full=c++
#LETTER NAME       ENABLED REFONLY NROLES MASTER DESCRIPTION
A       alias      no      no      0      NONE   namespace aliases
L       label      no      no      0      C      goto labels
N       name       no      no      0      NONE   names imported via using scope::symbol
U       using      no      yes     0      NONE   using namespace statements
c       class      yes     no      0      NONE   classes
d       macro      yes     no      1      C      macro definitions
e       enumerator yes     no      0      C      enumerators (values inside an enumeration)
f       function   yes     no      0      C      function definitions
g       enum       yes     no      0      C      enumeration names
h       header     yes     yes     2      C      included header files
l       local      no      no      0      C      local variables
m       member     yes     no      0      C      class, struct, and union members
n       namespace  yes     no      0      NONE   namespaces
p       prototype  no      no      0      C      function prototypes
s       struct     yes     no      0      C      structure names
t       typedef    yes     no      0      C      typedefs
u       union      yes     no      0      C      union names
v       variable   yes     no      0      C      variable definitions
x       externvar  no      no      0      C      external and forward variable declarations
z       parameter  no      no      0      C      function parameters inside function definitions

=end
class Ctags
  def initialize(opts)
    @opts = opts
    @data = []
  end

  def runctags(file)
    cmd = ["ctags", "-x", "--output-format=json", "--fields=+ln", "--c++-kinds=pms", "--language-force=c++", file]
    IO.popen(cmd, "rb") do |io|
      return io.read.strip
    end
  end

  def parse(file)
    tmp = []
    raw = runctags(file)
    if @opts.dumpjson then
      $stdout.puts(raw)
      return
    end
    raw.split(/\n/).each do |line|
      #$stderr.printf("line=<<<%s>>>", line)
      json = Oj.load(line)
      tmp.push(json)
    end
    @data.push(tmp)
  end

  def print_json(json)
    json.each do |chunk|
      k = chunk["kind"]
      #$stderr.printf("k=%p\n", k)
      next unless ((k == "function") || (k == "prototype"))
      pat = chunk["pattern"]
      pat = pat[2 .. -1]
      pat = pat[0 .. -3]
      pat.strip!
      if not pat.end_with?(";") then
        pat += ";"
      end
      $stdout.printf("%s\n", pat)
    end
  end

  def print_output
    @data.each do |json|
      print_json(json)
    end
  end
end

begin
  opts = OpenStruct.new({
    dumpjson: false
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit()
    }
    prs.on("-j", "--json", "dump raw json (for debugging, etc)"){
      opts.dumpjson = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("no files given\n")
  else
    ct = Ctags.new(opts)
    ARGV.each do |arg|
      ct.parse(arg)
    end
    ct.print_output
  end
end
