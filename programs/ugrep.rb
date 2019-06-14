#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "find"

=begin
Usage: grep [OPTION]... PATTERN [FILE]...
Search for PATTERN in each FILE or standard input.
PATTERN is, by default, a basic regular expression (BRE).
Example: grep -i 'hello world' menu.h main.c

Regexp selection and interpretation:
  -E, --extended-regexp     PATTERN is an extended regular expression (ERE)
  -F, --fixed-strings       PATTERN is a set of newline-separated strings
  -G, --basic-regexp        PATTERN is a basic regular expression (BRE)
  -P, --perl-regexp         PATTERN is a Perl regular expression
  -e, --regexp=PATTERN      use PATTERN for matching
  -f, --file=FILE           obtain PATTERN from FILE
  -i, --ignore-case         ignore case distinctions
  -w, --word-regexp         force PATTERN to match only whole words
  -x, --line-regexp         force PATTERN to match only whole lines
  -z, --null-data           a data line ends in 0 byte, not newline

Miscellaneous:
  -s, --no-messages         suppress error messages
  -v, --invert-match        select non-matching lines
  -V, --version             display version information and exit
      --help                display this help text and exit

Output control:
  -m, --max-count=NUM       stop after NUM matches
  -b, --byte-offset         print the byte offset with output lines
  -n, --line-number         print line number with output lines
      --line-buffered       flush output on every line
  -H, --with-filename       print the file name for each match
  -h, --no-filename         suppress the file name prefix on output
      --label=LABEL         use LABEL as the standard input file name prefix
  -o, --only-matching       show only the part of a line matching PATTERN
  -q, --quiet, --silent     suppress all normal output
      --binary-files=TYPE   assume that binary files are TYPE;
                            TYPE is 'binary', 'text', or 'without-match'
  -a, --text                equivalent to --binary-files=text
  -I                        equivalent to --binary-files=without-match
  -d, --directories=ACTION  how to handle directories;
                            ACTION is 'read', 'recurse', or 'skip'
  -D, --devices=ACTION      how to handle devices, FIFOs and sockets;
                            ACTION is 'read' or 'skip'
  -r, --recursive           like --directories=recurse
  -R, --dereference-recursive  likewise, but follow all symlinks
      --include=FILE_PATTERN  search only files that match FILE_PATTERN
      --exclude=FILE_PATTERN  skip files and directories matching FILE_PATTERN
      --exclude-from=FILE   skip files matching any file pattern from FILE
      --exclude-dir=PATTERN  directories that match PATTERN will be skipped.
  -L, --files-without-match  print only names of FILEs containing no match
  -l, --files-with-matches  print only names of FILEs containing matches
  -c, --count               print only a count of matching lines per FILE
  -T, --initial-tab         make tabs line up (if needed)
  -Z, --null                print 0 byte after FILE name

Context control:
  -B, --before-context=NUM  print NUM lines of leading context
  -A, --after-context=NUM   print NUM lines of trailing context
  -C, --context=NUM         print NUM lines of output context
  -NUM                      same as --context=NUM
      --color[=WHEN],
      --colour[=WHEN]       use markers to highlight the matching strings;
                            WHEN is 'always', 'never', or 'auto'
  -U, --binary              do not strip CR characters at EOL (MSDOS/Windows)
  -u, --unix-byte-offsets   report offsets as if CRs were not there

=end

def mayuse(opts, path)
  if not opts.excludefiles.empty? then
    findme = path
    if opts.use_basename then
      findme = File.basename(path)
    end
    opts.excludefiles.each do |rx|
      if findme.match(rx) != nil then
        return false
      end
    end
  end
  return true
end

def iterdirs(opts, dirs)
  rt = []
  dirs.each do |dir|
    Find.find(dir) do |item|
      if File.directory?(item) then
        if not opts.excludedirs.empty? then
          findme = item
          if opts.use_basename then
            findme = File.basename(item)
          end
          opts.excludedirs.each do |rx|
            if findme.match(rx) != nil then
              Find.prune!
            end
          end
        end
      elsif File.file?(item) then
        if mayuse(opts, item) then
          rt.push(item)
        end
      end
    end
  end
  return rt
end

def get_files(opts, dirs, files)
  dirfiles = iterdirs(opts, dirs)
  files.each do |fi|
    if mayuse(opts, fi) then
      dirfiles.push(fi)
    end
  end
  return dirfiles
end

def run_grep(opts, pat, dirs, files)
  cmdgrep = ["grep", "-P", pat, *opts.raw]
  files = get_files(opts, dirs, files)
  cmdgrep.push(*files)
  if $stdout.tty? then
    cmdgrep.push("--color=auto")
  end
  exec(*cmdgrep)
end

begin
  opts = OpenStruct.new({
    do_invert: false,
    excludedirs: [],
    excludefiles: [],
    raw: [],
  })
  OptionParser.new{|prs|
    prs.on("-C<n>", "--context=<n>", "output context"){|v|
      opts.raw.push("-C#{v}")
    }
    prs.on("-B<n>", "--before-context=<n>"){|v|
      opts.raw.push("-B#{v}")
    }
    prs.on("-A", "--after-context=<n>"){|v|
      opts.raw.push("-A#{v}")
    }
    prs.on("-h", "--no-filename"){|_|
      opts.raw.push("-h")
    }
    prs.on("-v", "--invert", "invert match"){|_|
      opts.raw.push("-v")
    }
    prs.on("-f<file>", "--file=<file>", "read pattern from <file>"){|v|
      opts.raw.push("--file=#{v}")
    }
    prs.on("-i", "--ignore-case"){|_|
      opts.raw.push("-i")
    }
    prs.on("-r"){|_|
      opts.raw.push("-r")
    }
    prs.on("-e<filename>", "--exclude=<filename>", "exclude <filename> (may be a regular expression)"){|v|
      opts.excludefiles.push(Regexp.new(v))
    }
  }.parse!
  dirs = []
  files = []
  pat = ARGV.shift
  if pat == nil then
    $stderr.printf("usage: ugrep [<flags...>] <pattern> [<items...>]\n")
  else
    if not ARGV.empty? then
      ARGV.each do |item|
        if File.directory?(item) then
          dirs.push(item)
        elsif File.file?(item) then
          files.push(item)
        else
          $stderr.printf("neither file, nor directory: %p\n", item)
        end
      end
    end
    run_grep(opts, pat, dirs, files)
  end
end


