#!/usr/bin/ruby

ROOT = "c:/gnulite"
PATHS = ["bin", "usr/bin"]

def get_bin(name)
  exe = (if not name.match?(/\.exe$/i) then sprintf("%s.exe", name) else name end)
  PATHS.each do |path|
    file = File.join(ROOT, path, exe)
    if File.file?(file) && File.executable?(file) then
      return file
    end
  end
  return nil
end

def listcommands
  printf("supported commands:\n")
  PATHS.each do |path|
    dir = File.join(ROOT, path)
    if File.directory?(dir) then
      Dir.each_child(dir) do |item|
        next unless item.match?(/\.exe$/i)
        fullp = File.join(dir, item)
        next unless File.file?(fullp)
        base = File.basename(item)
        stem = base.gsub(/\.exe$/i, "")
        printf("  %-30p (%p)\n", stem, fullp)
      end
    end
  end
end

def usage
  $stderr.puts("usage: lite <command> [<args>]")
  $stderr.puts("use 'lite -l' or 'lite --list' to show available commands")
  exit(0)
end

begin
  nargv = []
  sawpos = false
  verbose = false
  ARGV.each do |arg|
    if arg.match?(/^-/) && (sawpos == false) then
      if arg.match?(/^-(h|-help)$/) then
        usage
      elsif arg.match(/^-(v|-verbose)$/) then
        verbose = true
      elsif arg.match?(/^-(l|-list)$/) then
        listcommands
        exit(0)
      else
        $stderr.printf("did not understand option %p\n", arg)
        exit(1)
      end
    else
      sawpos = true
      nargv.push(arg)
    end
  end
  arg = nargv.shift
  if arg.nil? then
    $stderr.printf("need an argument here. try 'lite --help'\n")
    exit(1)
  else
    exe = get_bin(arg)
    if exe.nil? then
      $stderr.printf("could not find %p\n", arg)
      usage
    end
    if verbose then
      #$stderr.printf("verbose: exec(%p,\n%s\n)\n", exe, nargv.map{|a| sprintf("    %p", a) }.join(",\n"))
      $stderr.printf("verbose: exec: %s\n", [exe, *nargv].map(&:dump).join(" ") )
    end
    exec(exe, *nargv)
  end
end

