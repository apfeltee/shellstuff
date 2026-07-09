#!/usr/bin/ruby

=begin
print libraries matching a pattern in the search path of GCC.

basically, "echo /usr/lib/*foo*", but for all the directories.

if you think this is dumb, consider: on linux, libraries can be in no less than 4 different dirs,
a number which multiplies by each architecture.
and re-typing the same glob for each is just annoying.
=end

require "ostruct"
require "optparse"

LIBPATH= [
  "/usr/lib/gcc/x86_64-linux-gnu/13/",
  "/usr/lib/gcc/x86_64-linux-gnu/13/../../../x86_64-linux-gnu/",
  "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../lib/",
  "/lib/x86_64-linux-gnu/",
  "/lib/../lib/",
  "/usr/lib/x86_64-linux-gnu/",
  "/usr/lib/../lib/",
  "/usr/lib/gcc/x86_64-linux-gnu/13/../../../",
  "/lib/",
  "/usr/lib/",
]
  

class Findlib
  def initialize(opts)
    @opts = opts
    @seenst = []
  end

  def searchdirs_gcc()
    rt = {}
    # this will work fine with gcc and clang (and any derived from either).
    # but very definitely not others.
    # no cl.exe support, which lacks this functionality entirely.
    raw = IO.popen([@opts.gccexe, "-print-search-dirs"], "rb"){|io| io.read }
    raw.strip!
    raw.each_line do |line|
      m = line.match(/^\s*\b(?<key>\w+)\b:\s*=?(?<value>.*)/)
      if m == nil then
        $stderr.printf("failed to parse line %p\n", line)
      else
        key = m["key"].strip
        val = m["value"]
        putval = val
        if val.include?(":") then
          putval = []
          val = val.split(":").each do |d|
            st = File.stat(d) rescue nil
            if st then
              putval.push(File.absolute_path(d))
            end
          end
          putval.sort!
        end
        rt[key] = putval
      end
    end
    return rt
  end

  def searchdirs()
    r = searchdirs_gcc()
    return r
  end

  def canadd(itm)
    $stderr.printf("trying %p ...\n", itm)
    if File.file?(itm) then
      if @opts.excludelinks && File.symlink?(itm) then
        return false
      end
      
      st = File.stat(itm) rescue nil
      if st == nil then
        return false
      end
      if !@seenst.include?(st) then
        @seenst.push(st)
        return true
      end
    end
    return false
  end

  def findindir(d, namepat)
      globs = Dir.glob(d+"/"+namepat, File::FNM_CASEFOLD)
      actualglobs = []
      if !globs.empty? then
        globs.each do |itm|
          if canadd(itm) then
            actualglobs.push(itm)
          end
        end
        if !actualglobs.empty? then
          globs.each do |itm|
            printf("%s\n", itm)
          end
        end
      end
  
  end

  def findlib(namepat)
    $stderr.printf("searching for name %p\n", namepat)
    props = searchdirs()
    libdirs = (props["libraries"] | LIBPATH)
    libdirs.each do |libdir|
      $stderr.printf("searching in %p ...\n", libdir)
      findindir(libdir, namepat)
    end
  end
end

begin
  opts = OpenStruct.new({
    gccexe: "gcc",
  })
  OptionParser.new{|prs|
    prs.on("-s", "exclude links from output"){
      opts.excludelinks = true
    }
    prs.on("-x<s>", "path to GCC-compatible executable - defaults to 'gcc'"){|v|
      opts.gccexe = v
    }
  }.parse!
  namepat = ARGV[0]
  if !namepat then
    $stderr.printf("usage: findlib <pattern>\n")
    exit(1)
  else
    items = [namepat]
    if !namepat.match?(/^lib/) then
      items.push("lib#{namepat}")
    end
    fi = Findlib.new(opts)
    items.each do |item|
      fi.findlib(item)
    end
  end
end


