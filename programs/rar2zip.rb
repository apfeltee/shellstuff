#!/usr/bin/ruby

require "ostruct"
require "fileutils"
require "tmpdir"
require "shellwords"
require "optparse"

EXE_UNRAR = "unrar"
EXE_ZIP = "zip"
EXE_SEVENZIP = "win7z"

def shell(*cmd)
  $stderr.printf("shell: %p\n", cmd)
  system(*cmd)
end

def mayfail(fn, bool)
  if not bool then
    $stderr.printf("error: %s failed\n", fn)
    exit(1)
  end
  return bool
end

# check magic header of the top 20 bytes of the file
# rar files always start with "Rar!". so thats fun.
def israr?(file)
  head = File.read(file, 20)
  return (head[0 .. 5] == "Rar!\x1A\a")
end

# like File.realpath, except the file doesn't need to exist
def torealpath(path)
  dirn = File.dirname(path)
  base = File.basename(path)
  realdirn = File.realpath(dirn)
  return File.join(realdirn, base)
end

def towinpath(path)
  rx = /^\/cygdrive\/(.)\//
  realp = torealpath(path)
  if realp.match(rx) then
    return realp.gsub(rx, '\1:/')
  end
  return realp
end

def fixpath(file)
  abs = File.absolute_path(file)
  if RbConfig::CONFIG["target_os"].match(/cygwin/i) then
    return towinpath(abs)
  end
  return abs
end

def unrar(file, opts)
  cmd = [EXE_UNRAR, "x"]
  cmd.push("-p#{opts.passwd}") unless opts.passwd.nil?
  cmd.push(file)
  return shell(*cmd)
end

def zipfiles(destfile, files, opts)
  cmd = [EXE_ZIP, "-r", sprintf("-%d", opts.compressionlevel),  destfile, *files]
  shell(*cmd)
end

def sevenzipfiles(destfile, files, opts)
  cmd = [EXE_SEVENZIP, "a", "-t7z", destfile, sprintf("-mx%d", opts.compressionlevel), *files]
  shell(*cmd)
end

def either_zip_or_7z(realzip, files, opts)
  if opts.use7z then
    mayfail("7zfiles", sevenzipfiles(realzip, files, opts))
  else
    mayfail("zipfiles", zipfiles(realzip, files, opts))
  end
end

def rar2zip(rarfile, zipfile, opts)
  tempdir = Dir.mktmpdir 
  realzip = File.absolute_path(zipfile)
  # fwd for rm_rf
  files = []
  begin
    Dir.chdir(tempdir) do
      if mayfail("unrar", unrar(rarfile, opts)) then
        files = Dir.glob("*")
        if either_zip_or_7z(realzip, files, opts) then
          if opts.deleteafter then
            FileUtils.rm(rarfile, verbose: true)
          end
        end
        puts("done")
      end
    end
  ensure
    FileUtils.rm_rf(tempdir, verbose: true)
  end
end

def handle(file, opts)
  file = fixpath(file)
  if File.file?(file) then
    if israr?(file) then
      ext = File.extname(file)
      zipdest = fixpath(File.basename(file, ext) + opts.zipext)
      rar2zip(file, zipdest, opts)
    else
      $stderr.printf("error: %p does not look like a RAR file!\n", file)
    end
  else
    $stderr.printf("error: no such file: %p\n", file)
  end
end

begin
  userdecidedext = false
  opts = OpenStruct.new({
    passwd: nil,
    zipext: ".zip",
    compressionlevel: 0,
    deleteafter: false,
    use7z: false,
  })
  OptionParser.new{|prs|
    prs.on("-p<password>", "--password=<password>", "specify password for extraction"){|s|
      opts.passwd = s
    }
    prs.on("-e<ext>", "--ext=<ext>", "specify a different extension for zipfiles (default: '.zip')"){|s|
      opts.zipext = ((s[0] == '.') ? s : ('.' + s))
      userdecidedext = true
    }
    prs.on("-c<level>", "--compression=<level>", "specify compression level (default: 0)"){|s|
      opts.compressionlevel = s.to_i
    }
    prs.on("-d", "--deleteafter", "delete rar file if repacking was successful"){|_|
      opts.deleteafter = true
    }
    prs.on("-7", "--sevenzip", "use 7zip instead of zip (you need to have 7z in your PATH!)"){|_|
      opts.use7z = true
      if not userdecidedext then
        opts.zipext = ".7z"
      end
    }
  }.parse!
  if ARGV.empty? then
    puts("no files specified. try '-h'")
  else
    ARGV.each do |arg|
      handle(arg, opts)
    end
  end
end
