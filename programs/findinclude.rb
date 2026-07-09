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
require "open3"

LIBPATH= [
  "/usr/include/c++/13",
  "/usr/include/x86_64-linux-gnu/c++/13",
  "/usr/include/c++/13/backward",
  "/usr/lib/gcc/x86_64-linux-gnu/13/include",
  "/usr/local/include",
  "/usr/include/x86_64-linux-gnu",
  "/usr/include",

]
  

class Findlib
  def initialize(opts)
    @opts = opts
    @seenst = []
  end


  def getincsfor(lang)
    rt = []
    #raw = IO.popen([@opts.gccexe, "-xc", "-E", "-Wp,-v", "-"], "r+"){|io|
    raw = Open3.popen2(*[@opts.gccexe, "-x#{lang}", "-E", "-Wp,-v", "-"], {:err => [:child, :out]}) { |inp, outp|
      inp.write(""); inp.close_write; outp.read
    }
    raw.strip!
    raw.each_line do |line|
      line.strip!
      if !line.match?(/^\s*#/) && !line.match?(/^\s*end\s*of/i) && !line.match?(/^ignoring/) then
        #$stderr.printf("line=%p\n", line)
        rt.push(line)
      else
       #$stderr.printf("-- %s\n", line)
      end
    end
    return rt
  end

  def searchdirs_gcc()
    rt = []
    rt.push(*getincsfor("c"))
    rt.push(*getincsfor("c++"))
    return rt
  end

  def searchdirs()
    r = searchdirs_gcc()
    return r
  end

  def canadd(itm)
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

  def findindirglob(d, namepat)
    rt = []
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
          rt.push(itm)
        end
      end
    end
    if rt.empty? then
      return nil
    end
    return rt
  end

  def findindir(d, namepat)
    rt = []
    path = File.join(d, namepat)
    if File.file?(path) then
      rt.push(path)
      return rt
    end
    return findindirglob(d, namepat)
  end

  def printindir(d, namepat)
    rc = 0
    res = findindir(d, namepat)
    if res != nil then
      res.each do |r|
        printf("%s\n", r)
        rc += 1
      end
    end
    return rc
  end

  def findlib(namepat)
    rc = 0
    libdirs = searchdirs()
    libdirs.push(*LIBPATH)
    #$stderr.printf("libdirs=%p\n", libdirs)
    libdirs.uniq!
    libdirs.each do |libdir|
      rc += printindir(libdir, namepat)
    end
    if rc == 0 then
      $stderr.printf("cannot find %p\n", namepat)
    end
  end
end

begin
  opts = OpenStruct.new({
    gccexe: "gcc",
  })
  OptionParser.new{|prs|
    prs.on("-s"){
      opts.escludelinks = true
    }
    prs.on("-x<s>"){|v|
      opts.gccexe = v
    }
  }.parse!
  namepat = ARGV[0]
  if !namepat then
    $stderr.printf("usage: findlib <pattern>\n")
    exit(1)
  else
    Findlib.new(opts).findlib(namepat)
  end
end


