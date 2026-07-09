#!/usr/bin/ruby

begin
  opts = ["-fdump-tree-original", "-fdump-tree-optimized"]
  gccexe = "gcc"
  nargv = []
  ARGV.each do |arg|
    arg = arg.scrub
    if arg.match?(/^-std=(c|gnu)\+\+/) then
      gccexe = "g++"
      opts.push("-xc++")
    else
      if arg.match?(/-xc\+\+/) then
        gccexe = "g++"
      end
      nargv.push(arg)
    end
  end
  cmd = [gccexe, *nargv]
  exec(*cmd)
end





