#!/usr/bin/ruby

require "ostruct"
require "optparse"

DOUBLE_EXTENSIONS = [
  %w(tar gz),
  %w(tar bz2),
  %w(tar xz),
  %w(tar z),
  %w(tar 7z),
  %w(tar md5),
  # cygwin uses this, idk about others
  %w(dll a),
  # windows interface dlls
  %w(dll mui),
]

def isdoubleext(extparts)
  if extparts.length > 2 then
    # if this is something like foo.tar.gz, then
    # lastpart is now "gz"
    lastpart = extparts[-1].downcase
    # ... and beflast is "tar"
    beflast = extparts[-2].downcase
    DOUBLE_EXTENSIONS.each do |dbe|
      #$stderr.printf("isdoubleext(%p): dbe=%p beflast=%p lastpart=%p\n", extparts, dbe,  beflast, lastpart)
      if (beflast == dbe[0]) && (lastpart == dbe[1]) then
        return true
      end
    end
  end
  return false
end

def parse_path(path)
  dir = File.dirname(path)
  base = File.basename(path)
  extparts = base.split(".").reject(&:empty?)
  modparts = extparts.dup
  tmpstem = modparts.shift
  tmpext = modparts.pop
  # a dotfile -- needs to be handled differently!
  isdotfile = (base[0] == ".")
  if isdoubleext(extparts) then
    last = tmpext
    bef = modparts.pop
    tmpext = [bef, last].join(".")
  end
  if (not modparts.empty?) then
    tmpstem = [tmpstem, *modparts].join(".")
  end
  return dir, tmpstem, tmpext
end

def chext(files, extn, opts)
  verbose = opts.verbose
  debug = opts.debug
  extn = (if (extn[0] == '.') then extn[1 .. -1] else extn end).strip
  files.each do |file|
    if File.file?(file) || opts.testonly then
      dir, stem, ext = parse_path(file)
      $stderr.printf("chext: deparsed %p as <dir=%p stem=%p ext=%p>\n", file, dir, stem, ext) if debug
      newbase = sprintf("%s.%s", stem, extn)
      newpath = File.join(dir, newbase)
      if File.file?(newpath) && (opts.force == false) then
        $stderr.printf("error: file %p already exists! specify '-f' to overwrite\n", newpath)
        next
      end
      begin
        $stderr.printf("chext: renaming %p to %p\n", file, newpath) if verbose
        if not opts.testonly then
          File.rename(file, newpath)
        end
      rescue => ex
        $stderr.printf("error: rename for %p failed: (%s) %s\n", file, ex.class.name, ex.message)
      end
    else
      $stderr.printf("error: not a file: %p\n", file)
    end
  end
end

def get_args
  if ARGV.empty? then
    if $stdin.tty? then
      $stderr.printf("usage: chext -e<new-extension> <files...>\n")
      exit(1)
    else
      return $stdin.readlines.map(&:strip).reject(&:empty?)
    end
  else
    return ARGV
  end
end

begin
  extn = nil
  opts = OpenStruct.new({
    force: false,
    verbose: false,
    testonly: false,
    debug: false,
  })
  OptionParser.new{|prs|
    prs.on("-e<ext>", "--new-extension=<ext>", "specify new extension"){|s|
      extn = s
    }
    prs.on("-f", "--[no-]force", "force overwriting of existing files"){|v|
      opts.force = v
    }
    prs.on("-v", "--[no-]verbose", "toggle verbose messages"){|v|
      opts.verbose = v
    }
    prs.on("-d", "--[no-]debug", "toggle debug message"){|v|
      opts.debug = v
    }
    prs.on("-t", "--[no-]test", "combined with '-v', will show what would be done without touching files"){|v|
      opts.testonly = v
    }
  }.parse!
  if extn == nil then
    $stderr.printf("you must specify a new extension with '-e'! (i.e., '-efoo')\n")
    exit(1)
  end
  args = get_args
  chext(args, extn, opts)
end

