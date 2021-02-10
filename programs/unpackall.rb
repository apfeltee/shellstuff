#!/usr/bin/ruby -w

require "ostruct"
require "optparse"
require "pathname"
require "fileutils"
require "find"
require "shellwords"
require "open3"

# mapping for archives that 7z can't handle (yet)
# name_of_function => list_of_file_extensions
EXES = {
  #do_zip: ["zip"],
  #do_rar: ["rar"],
  do_lzh: ["lzh", "lha"],
  do_zoo: ["zoo"],
  # really old archives use .ark, but are actually .arc
  do_arc: ["arc", "ark"],
  # ANCIENT SHIT
  do_lbr: ["lbr"],
  do_sit: ["sit"],
  do_lzx: ["lzx"],
}

PKGRE = /\.(zip|rar|7z|tar|arj|dsk|cpio|pax|#{EXES.values.flatten.join("|")})$/i

def fail(fmt, *a)
  $stderr.printf("ERROR: %s\n", sprintf(fmt, *a))
  exit(1)
end

class UnpackAll
  def initialize(opts)
    @opts = opts
    @failed = []
    @failfh = nil
    @processedfh = nil
    @flines = 0
    if @opts.failfile != nil then
      @failfh = File.open(@opts.failfile, "wb")
    end
    if @opts.processedfile != nil then
      @processedfh = File.open(@opts.processedfile, "ab")
    end
  end

  def msg(ofh, templ, fmt, *a, **kw)
    ofh.printf(templ, (
      if (a.empty? && kw.empty?) then
        fmt
      else
        if a.empty? then
          sprintf(fmt, **kw)
        elsif kw.empty? then
          sprintf(fmt, *a)
        else
          sprintf(fmt, *a, **kw)
        end
      end
    ))
  end

  def note(fmt, *a, **kw)
    msg($stderr, "- %s\n", fmt, *a, **kw)
  end

  def complain(fmt, *a, **kw)
    msg($stderr, "WARNING: %s\n", fmt, *a, **kw)
  end

  def find_extractor(ext)
    ext = (
      if (ext != nil) && (ext[0] == ".") then
        ext = ext[1 .. -1]
      else
        if ext == nil then
          ""
        else
          ext
        end
      end
    ).downcase
    EXES.each do |recv, exts|
      if exts.include?(ext) then
        return recv
      end
    end
    return nil
  end

  def find_command(name)
    ENV["PATH"].split(":").each do |elem|
      base = File.join(elem, name)
      more = %w(exe bat cmd).map{|ext|  base + "." + ext }
      if File.file?(base) then
        return base
      else
        more.each do |mp|
          return mp if File.file?(mp)
        end
      end
    end
    return nil
  end

  def shsystem(cmd, idx, ac)
    $stdout.printf("[%-5d of %-5d]\n", idx+1, ac)
    return system(*cmd)
  end

  def make_outdir(basedir, stem)
    if File.exist?(stem) then
      ci = 0
      while true do
        buf = sprintf("%s_%d", stem, ci)
        if not File.exist?(buf) then
          return buf
        end
        ci += 1
      end
    end
    return stem
  end



  # wrapper for commands that have no flag to set output directory
  # this is usually the case for really old commands (arc, zoo, etc)
  # first command is an array with the extraction command, and
  # a "%" denoting the filename, i.e.: ["foo", "-bar", "%"]
  # which becomes ["foo", "-bar", "somefile.foo"]. the "%" can
  # appear whereever, obviously.
  def extractor_has_no_output_flag(execmd, basedir, file, odir, idx, ac)
    FileUtils.mkdir_p(odir)
    rfile = File.absolute_path(file)
    absodir = File.absolute_path(File.join(basedir, odir))
    relfile = Pathname.new(rfile).relative_path_from(absodir).to_s
    #relfile = Pathname.new(absodir).relative_path_from(rfile).to_s
    relfile =File.join("..", file)
    #p [basedir, file, rfile, absodir, relfile]
    #exit
    begin
      Dir.chdir(odir) do
        $stderr.printf("rfile: %p\n", rfile)
        realcmd = execmd.map{|v|
          if v == "%" then
            relfile
          else
            v
          end
        }
        return shsystem(realcmd, idx, ac)
      end
    ensure
      if File.empty?(odir) then
        begin
          Dir.rmdir(odir)
        rescue
        end
      end
    end
  end


  ##
  ## this is where individual extractor callbacks are defined.
  ## most tools lack the means of specifing an output directory, so
  ## that functionality is emulated through extractor_has_no_output_flag().
  ##
  def do_zip(basedir, file, odir, idx, ac)
    return extractor_has_no_output_flag(["unzip", "-x", "%"], basedir, file, odir, idx, ac)
  end

  def do_arc(basedir, file, odir, idx, ac)
    return extractor_has_no_output_flag(["arc", "xo", "%"], basedir, file, odir, idx, ac)
  end

  def do_lbr(basedir, file, odir, idx, ac)
    return extractor_has_no_output_flag(["unlbr", "-Loa", "%"], basedir, file, odir, idx, ac)
  end

  def do_lzh(basedir, file, odir, idx, ac)
    cmd = [
      "lha", "xfw=#{odir}", file
    ]
    return shsystem(cmd, idx, ac)
  end

  def do_zoo(basedir, file, odir, idx, ac)
    return extractor_has_no_output_flag(["zoo", "x", "%"], basedir, file, odir, idx, ac)
  end
  
  def do_sit(basedir, file, odir, idx, ac)
    return extractor_has_no_output_flag(["unsit", "%"], basedir, file, odir, idx, ac)
  end

  def do_lzx(basedir, file, odir, idx, ac)
    return extractor_has_no_output_flag(["unlzx", "-x", "%"], basedir, file, odir, idx, ac)
  end

  def run_extractor(ext, basedir, file, odir, idx, ac)
    $stderr.printf("run_extractor(ext=%p, basedir=%p, file=%p, odir=%p) ...\n", ext, basedir, file, odir)
    if (recv=find_extractor(ext)) != nil then
      # sub-processors may return false - in that case, it will be taken
      # over by 7z again
      $stderr.printf("** running extractor %p\n", recv)
      if self.send(recv, basedir, file, odir, idx, ac) then
        return true
      end
    end
    cmd = [
      @opts.sevenzip, "x", "-y"
    ]
    if @opts.password != nil then
      cmd.push("-p#{@opts.password}")
    end
    cmd.push("-o#{odir}")
    cmd.push(file)
    return shsystem(cmd, idx, ac)
  end

  def procitem(name, recv, *args, &b)
    b.call
    begin
      #send(recv, *args)
      recv.call(*args)
    rescue => ex
      $stderr.printf("failed: (%s) %s", ex.class.name, ex.message)
    else
      $stderr.print("ok")
    ensure
      $stderr.print("\n")
    end
  end

  def delfile(file)
    procitem("delitem", File.method(:delete), file){
      $stderr.printf("deleting %p ... ", file)
    }
  end

  def deldir(dir)
    procitem("deldir", Dir.method(:rmdir), dir){
      $stderr.printf("removing directory %p ... ", dir)
    }
  end

  def mvfile(ffrom, fto)
    procitem("mvfile", File.method(:rename), ffrom, fto){
      $stderr.printf("renaming %p to %p ... ", ffrom, fto)
    }
  end

  def unzip(file, idx, ac)
    base = File.basename(file)
    ext = File.extname(base)
    stem = File.basename(base, ext)
    dir = File.dirname(file)
    if @processedfh != nil then
      @processedfh.puts(file)
    end
    Dir.chdir(dir) do
      #if system("win7z", "x", "-y", "-pfuckoff", base, "-o#{stem}") then
      odir = make_outdir(dir, stem)
      if run_extractor(ext.downcase[1 .. -1], dir, base, odir, idx, ac) then
        delfile(base)
        if File.directory?(odir) then
          items = Dir.children(odir).map{|s| File.join(odir, s) }
          if items.length == 1 then
            if File.exist?(items[0]) then
              item = items[0]
              origname = File.basename(item)
              tmpname = (origname+"."+Time.now.usec.to_s)
              if not File.exist?(origname) then
                mvfile(item, tmpname)
                deldir(odir)
                mvfile(tmpname, origname)
                #system("mv", "-v", item, tmpname)
                #system("rmdir", "-v", stem)
                #system("mv", "-v", tmpname, origname)
              end
            end
          end
        end
        if @opts.delafter then
          begin
            File.delete(file)
          rescue => ex
            $stderr.printf("failed to delete %p: (%s) %s\n", file, ex.class.name, ex.message)
          end
        end
      else
        @failed.push(file)
        if @failfh != nil then
          @failfh.puts(file)
          @failfh.flush
        end
      end
    end
  end

  def walk(dir)
    note("scanning %p ...", dir)
    afiles = []
    Find.find(dir) do |path|
      next unless File.file?(path)
      extn = File.extname(path).downcase
      if path.scrub.match?(PKGRE) || @opts.extraexts.include?(extn) then
        note("found %p", path)
        afiles.push(path)
      end
    end
    acount = afiles.length
    note("found %d files", acount)
    afiles.each.with_index do |file, i|
      if @opts.findonly then
        $stdout.puts(file)
      else
        unzip(file, i, acount)
      end
    end
  end

  def status
    begin
      if not @failed.empty? then
        complain("failed to unpack these %d archives:", @failed.length)
        @failed.each do |f|
          complain("   %p", f)
        end
      end
    ensure
      if @failfh != nil then
        @failfh.close
      end
    end
    if @failed.empty? && (@opts.failfile != nil) && File.file?(@opts.failfile) then
      File.delete(@opts.failfile)
    end
  end

end



def findexe(name, mustfail, wantednames)
  ENV["PATH"].split(":").each do |dir|
    wantednames.each do |name|
      fp = File.join(dir, name)
      if File.file?(fp) && File.executable?(fp) then
        return fp
      end
    end
  end
  if mustfail then
    fail("could not find %s in your PATH; tried %s", name, wantednames.map(&:dump).join(", "))
  end
  return nil
end

def find7z()
  return findexe("sevenzip", true, ["win7z", "7z.exe"])
end

def findmvsingle()
  return findexe("mvsingle", false, ["mvsingle"])
end

begin
  opts = OpenStruct.new({
    sevenzip: find7z(),
    password: nil,
    delafter: false,
    findonly: false,
    failfile: nil,
    processedfile: nil,
    extraexts: [],
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-r", "--regex", "print regex used to find files, and exit"){
      puts(PKGRE)
      exit(0)
    }
    prs.on("-z<path>", "-x<path>", "--7z=<path>", "specify path to 7z"){|v|
      opts.sevenzip = v
    }
    prs.on("-p<str>", "--password=<str>", "specify password (if needed)"){|v|
      opts.password = v
    }
    prs.on("-w", "--overwrite", "overwrite exsting directories"){
      opts.overwrite = true
    }
    # not used atm
    prs.on("-o<dir>", "--out=<dir>", "specify different output directory than the directories of the archives"){|v|
      opts.outputdir = v
    }
    prs.on("-d", "--delete", "delete after successful unpacking"){
      opts.delafter = true
    }
    prs.on("-s", "--find", "find archive files only, does not unpack anything"){
      opts.findonly = true
    }
    prs.on("-d<f>", "--finished=<f>", "write names of processed files to <f>"){|v|
      opts.processedfile = v
    }
    prs.on("-f<path>", "--fail=<path>", "write paths of archives that failed to extract to <path>"){|v|
      opts.failfile = v
      if File.exist?(v) then
        if File.directory?(v) then
          $stderr.printf("unpackall: --fail: path %p is a directory\n", v)
        end
        $stderr.printf("unpackall: --fail: refusing to overwrite an existing path\n")
        exit(1)
      end
    }
    prs.on("-e<s>", "--ext=<s>", "add to list of extensions to search"){|v|
      v.strip!
      v = (if (v[0] != '.') then ('.' + v) else v end)
      opts.extraexts.push(v)
    }
  }.parse!
  ua = UnpackAll.new(opts)
  if ARGV.empty? then
    fail("need to specify a directory")
  else
    begin
      ARGV.each do |arg|
        if File.directory?(arg) then
          ua.walk(arg)
        else
          ua.complain("not a directory %p\n", arg)
        end
      end
    ensure
      ua.status
    end
  end
end

