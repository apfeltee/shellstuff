#!/usr/bin/ruby

require "optparse"
require "find"
require "parallel"

USELESS = File.absolute_path(File.join(__dir__, "_maybeuseless", "useless"))

EXTS =
[
  "c",
  "cc",
  "cpp",
  "cxx",
  "hxx",
  "hh",
  "c++",
  "h++",
  "f",
  "f77",
  ### too many false positives
  "for",
  "f95",
  "cgi",
  "php",
  "pas",
  "p",
  "pp",
  "java",
  "rs",
  "cs",
  "ml",
  "cob",
  "py",
  "rb",
  "bas",
]

SOURCEFILES = /\.(#{EXTS.map{|s| Regexp.quote(s) }.join("|")})$/i

def haswanted(dir)
  cnt = 0
  Find.find(dir) do |path|
    next unless File.file?(path)
    if path.scrub.match?(SOURCEFILES) then
      cnt += 1
    end
  end
  return (cnt > 0)
end

def walk(root, dest, realdel, pretend)
  Parallel.each(Dir.glob(root+"/*"), in_threads: 20) do |dir|
    next unless File.directory?(dir)
    if not haswanted(dir) then
      if realdel then
        $stderr.printf("rm: %p ...\n", dir)
        system("rm", "-rf", dir)
      else
        if pretend then
          $stderr.printf("deleting: %p\n", dir)
        else
          system("mv", "-v", dir, dest)
        end
      end
    end
  end
end

begin
  dest = USELESS
  pretend = false
  deleteinstead = false
  OptionParser.new{|prs|
    prs.on("-f", "-r", "-d", "delete directories directly, instead of moving them"){
      deleteinstead = true
    }
    prs.on("-o<dir>", "set destination for deleting (default: #{USELESS.dump})"){|v|
      dest = v
    }
    prs.on("-t", "-p", "show what would be done instead of deleting"){
      pretend = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.puts("filtnosrc <dir> ...")
    exit(1)
  else
    if not File.directory?(dest) then
      if not system("mkdir", "-p", dest) then
        $stderr.printf("failed to mkdir %p!\n")
        exit(1)
      end
    end
    ARGV.each do |d|
      walk(d, dest, deleteinstead, pretend)
    end
  end
end

