#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "fileutils"

def complain(pre, fmt, *args)
  str = (if args.empty? then fmt else sprintf(fmt, *args) end)
  $stderr.printf("%s: %s\n", pre, str)
end

def err(fmt, *args)
  complain("error", fmt, *args)
end

def warn(fmt, *args)
  complain("warning", fmt, *args)
end

def mustwrite?(path)
  if File.file?(path) then
    return (File.size(path) == 0)
  else
    return true
  end
  return false
end

def newdir(path)
  FileUtils.mkdir_p(path, verbose: true)
end

def touchfile(path)
  if File.exist?(path) then
    if File.directory?(path) then
      warn("touch: %p is a directory")
    end
    # don't actually do anything - including overwriting attribs
  else
    File.open(path, "w").close
  end
end

def newfile(path, set_xbit, editafterwards)
  #FileUtils.touch(path, verbose: true)
  touchfile(path)
  if mustwrite?(path) then
    File.write(path, "\n")
  end
  if set_xbit then
    FileUtils.chmod("a+x", path)
  end
  if editafterwards then
    system("edit", path)
  end
end

=begin
Usage: $g_selfname [-d] [-e] [-x] <path> [<another-path> ...]
by default, $g_selfname merely creates new files. not very exciting, huh?

options:
  -h    show this help, and exit.
  -d    create a directory
  -e    edit the file after creation. requires 'edit'. cannot be used with directories.
  -x    make the file executable after creating. cannot be used with directories.
=end
begin
  opts = OpenStruct.new
  prs = OptionParser.new{|prs|
    prs.on("-d", "--directory", "create a directory"){|v|
      opts.createdir = true
    }
    prs.on("-e", "--edit", "edit file after creating"){|v|
      opts.editafter = true
    }
    prs.on("-x", "--setxbit", "make file executable"){|v|
      opts.setxbit = true
    }
  }
  prs.parse!
  if ARGV.empty? then
    puts(prs.help)
    exit(1)
  else
    begin
      if opts.createdir && (opts.editafter || opts.setxbit) then
        $stderr.puts("error: cannot use '-d' with '-e' or '-x'")
        exit(1)
      end
      ARGV.each do |arg|
        if opts.createdir then
          newdir(arg)
        else
          newfile(arg, opts.setxbit, opts.editafter)
        end
      end
    rescue => e
      $stderr.puts("uncaught error: (#{e.class}) #{e.message}")
      exit(1)
    end
  end
end
