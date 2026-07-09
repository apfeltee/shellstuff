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

def newfile(path, set_xbit, editafterwards, trycount=0)
  #FileUtils.touch(path, verbose: true)
  dn = File.dirname(path)
  begin
    touchfile(path)
  rescue => ex
    if ex.is_a?(Errno::ENOENT) then
      warn("attemping to mkdir base %p of %p", dn, path) if (trycount == 0)
      if trycount == 3 then
        $stderr.printf("failed to try to create base directory %p too many times. bailing\n", dn)
        raise ex
      end
      begin
        FileUtils.mkdir_p(dn)
        # if we're still here, then we can re-call again, that is, try again.
        return newfile(path, set_xbit, editafterwards, trycount + 1)
      rescue => subex
        raise ex
      end
    end
    raise ex
  end
  if mustwrite?(path) then
    File.write(path, "\n")
  end
  if set_xbit then
    FileUtils.chmod("a+x", path)
  end
  if editafterwards then
    system(File.expand_path("~/bin/edit"), path)
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
    #rescue => e
      #$stderr.puts("uncaught error: (#{e.class}) #{e.message}")
      #exit(1)
    end
  end
end
