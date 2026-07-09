#!/usr/bin/ruby

=begin
helper script that does what 'gcc -S ...' does, except, it strips the assembly
output of .seh clauses (for inspection; the resulting program will likely not function),
as well as outputting llvm IR.
it just does it in a less typing-heavy way.
=end

require "ostruct"
require "optparse"
require "shellwords"

def printcmd(cmd)
  $stderr.printf("running: %s\n", cmd.map{|s| s.shellescape }.join(" "))
end

def do_compile(opts, infile, ofile)
  sb = StringIO.new
  sehcnt = 0
  sehrx = /^\s*\.seh_.*$/
  mo = opts.moreopts
  cmd = [opts.gcc, "-S", *mo, infile]
  if opts.optimize != nil then
    cmd.push("-O#{opts.optimize}")
  end
  if (wantllvm = (opts.asmflavor == "llvm")) || (opts.keepseh) then
    if wantllvm then
      $stderr.printf("no postprocessing done because asmflavor=llvm\n")
    end
    $stderr.printf("writing outputfile to %p\n", ofile)
    cmd.push("-o", ofile)
    printcmd(cmd)
    exec(*cmd)
    return
  end
  cmd.push("-masm=#{opts.asmflavor}")
  cmd.push("-o-")
  printcmd(cmd)
  IO.popen(cmd) do |io|
    io.each_line do |ln|
      if ln.match?(sehrx) then
        sehcnt += 1
      else
        sb.write(ln)
      end
    end
  end
  if sehcnt == 0 then
    $stderr.printf("input file %p has no '.seh' instruction, so nothing to do.\n", infile)
  else
    $stderr.printf("writing outputfile to %p\n", ofile)
    File.open(ofile, "wb") do |fh|
      fh.write(sb.string)
    end
  end
end

def specifics(opts, file)
  # dumb deep clone hack. so sue me
  nopts = OpenStruct.new(eval("opts.to_h"))
  oext = "s"
  if nopts.asmflavor == "llvm" then
    nopts.gcc = "clang"
    nopts.moreopts.push("-emit-llvm")
    oext = "ll"
  end
  if file.match?(/\.(cpp|cc|cxx|c\+\+)$/) then
    if nopts.gcc == "clang" then
      nopts.gcc = "clang++"
    else
      nopts.gcc = "g++"
    end
    nopts.moreopts.push("-std=c++20")
  end
  dirn = File.dirname(file)
  base = File.basename(file)
  ext = File.extname(base)
  stem = File.basename(base, ext)
  ofile = File.join(dirn, stem + "." + oext)
  return do_compile(nopts, file, ofile)
end

begin
  opts = OpenStruct.new({
    gcc: "gcc",
    asmflavor: "intel",
    moreopts: [],
    keepseh: false,
    optimize: nil,
  })
  OptionParser.new{|prs|
    prs.on("-f<flavor>", "--flavor=<flavor>", "what kind of asm flavor to emit (att/intel/llvm - the latter requires clang)"){|v|
      opts.asmflavor = v
    }
    prs.on("-s", "--seh", "keep .seh clauses. this just runs '$compiler -S ...'"){
      opts.keepseh = true
    }
    prs.on("-O[<val>]", "--optimize[=<val>]"){|v|
      opts.optimize = ((v == nil) ? "" : v)
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("need some filenames here. try '--help'\n")
    exit(1)
  else
    ARGV.each do |arg|
      specifics(opts, arg)
    end
  end
end


