#!/usr/bin/ruby

## like linux' 'ldd', but for PE files.
require "ostruct"
require "optparse"
require "pedump"
require "colorize"
#require "pry-byebug"

def make_paths(fdir)
  envpaths = ["."] + ENV["PATH"].split(":")
  envpaths.push(fdir)
  # probably would need to figure out if
  # we're on cygwin, and also if it's 32bit or 64bit, since
  # that actually matters a lot
  if true then
    if ENV["ORIGINAL_PATH"] then
      envpaths += ENV["ORIGINAL_PATH"].split(":")
    end
    envpaths.map!{|path|
      if path.start_with?("/cygdrive") then
        path.gsub(/^\/cygdrive\/(.)(.*)/, '\1:\2')
      else
        path
      end
    }
    envpaths.push("c:/windows/system32", "c:/windows/syswow64")
  end
  return envpaths
end

def guesspath(dll, envpaths)
  searchme = dll.dup
  envpaths.each do |dir|
    path = File.join(dir, searchme)
    #$stderr.printf("guesspath(%p, ...) path=%p\n", dll, path)
    if File.file?(path) then
      return path
    end
  end
  return nil
end

class LDDx
  def initialize(opts)
    @seen = []
    @recursecache = []
    @opts = opts
  end

  def verbose(fmt, *args)
    if @opts.verbose then
      str = if args.empty? then fmt else sprintf(fmt, *args) end
      $stderr.puts("lddx:verbose: #{str}")
    end
  end

  def tryresolve(filename, wanted)
    abs = File.absolute_path(filename)
    base = File.basename(wanted)
    dir = File.dirname(abs)
    dbs = base.downcase
    foundany = 0
    Dir.glob(dir+"/*") do |item|
      next unless File.file?(item)
      ib = File.basename(item)
      ibs = ib.downcase
      if (ibs == dbs) then
        $stdout.printf("      found %p\n", item)
        foundany += 1
      end
    end
    if foundany == 0 then
      $stdout.printf("      could not resolve!\n")
    end
  end

  def do_ldd(filename)
    recurse = []
    errcount = 0
    doprint = (@opts.testonly == false)
    filepath = File.absolute_path(filename)
    filedir = File.dirname(filepath)
    basename = File.basename(filename).downcase
    if @seen.include?(basename) then
      return errcount
    end
    @seen.push(basename)
    begin
      verbose("opening %p ...", filename)
      File.open(filename, "rb") do |fh|
        pe = PEdump.new(fh)
        imports = pe.imports
        if imports.empty? then
          verbose("file has no imports, nothing to do")
          return errcount
        end
        tmp = []
        longest = imports.map{|ip| ip.module_name }.max_by(&:length)
        verbose("%p has %d imports", filename, imports.length)
        pad = (if longest.nil? then 0 else longest.length end)
        pe.imports.each do |imp|
          name = imp.module_name
          #binding.pry
          # some old binaries seem to pad binaries with space for some reason ...
          # some kind of oddity from pre-NT?
          if name.match(/\s$/) then
            name.strip!
          end
          ofs = nil
          ofs = imp.OriginalFirstThunk rescue 0 # i think? i'm not sure, actually.
          path = guesspath(name, make_paths(filedir))
          strpath = (path || "(not found)".colorize(:red))
          if not path then
            errcount += 1
          end
          if not @recursecache.include?(File.basename(strpath).downcase) then
            tmp.push([name, ofs, path, strpath])
          end
          if @opts.recursive then
            if path then
              @recursecache.push(path.downcase)
            end
          end
          recurse.push(path) if path
        end
        if doprint then
          if not @opts.filesonly then
            puts("#{filename}:")
          end
          tmp.each do |info|
            name, ofs, path, strpath = info
            if @opts.filesonly then
              printf("%s\n", strpath)
            elsif @opts.lddformat then
              ofsfmt = sprintf("0x%X", ofs).colorize(:blue)
              printf("    %-#{pad}s => %s (%s)\n", name, strpath, ofsfmt)
            else
              strpath = (path || name)
              printf("  (0x%X) %s%s\n", ofs, strpath, (path == nil ? " (not found)" : ""))
            end
            if (@opts.resolve == true) && (path == nil) then
              tryresolve(filename, strpath)
            end
          end
        end
      end
    rescue => err
      $stderr.puts("lddx: error reading #{filename.dump}: (#{err.class}) #{err.message}")
      $stderr.puts("backtrace:")
      err.backtrace.each do |line|
        $stderr.puts("   #{line}")
      end
    end
    if @opts.recursive then
      recurse.each do |r|
        if not @recursecache.include?(r) then
          do_ldd(r)
        end
      end
    end
    return errcount
  end
end

begin
  $stdout.sync = true
  if not $stdout.tty? then
    String.disable_colorization = true
  end
  opts = OpenStruct.new({
    lddformat: true,
    printfuncs: false,
    testonly: false,
    filesonly: false,
  })
  prs = OptionParser.new{|prs|
    prs.on("-v", "--verbose", "toggle verbose output"){|v|
      opts.verbose = v
    }
    prs.on("-r", "--[no-]recursive", "perform lddx on every module name"){|v|
      opts.recursive = v
    }
    prs.on(nil, "--[no-]lddformat", "use traditional 'ldd' style output"){|v|
      opts.lddformat = v
    }
    prs.on("-i", "--printfuncs", "also print imported symbols"){|_|
      opts.printfuncs = true
    }
    prs.on("-t", "--test", "only test; don't print (for scripting)"){|_|
      opts.testonly = true
    }
    prs.on("-f", "--files", "print files only"){|_|
      opts.filesonly = true
    }
    prs.on("-q", "--resolve", "attempt to resolve paths for missing DLLs"){|_|
      opts.resolve = true
    }
  }
  prs.parse!
  if ARGV.empty? then
    $stderr.puts("no file arguments given!")
    $stderr.puts(prs.help)
  else
    ec = 0
    ctx = LDDx.new(opts)
    ARGV.each do |arg|
      ec += ctx.do_ldd(arg)
    end
    exit(ec > 0 ? 1 : 0)
  end
end
