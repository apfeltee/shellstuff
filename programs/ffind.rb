#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "open3"

def size_to_readable(size)
  # byte, kilobyte, megabyte, gigabyte, terabyte, petabyte, exabyte, zettabyte
  # the last two seem... unlikely, tbh
  units = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']
  if (size == 0) then
    return '0B'
  end
  exp = (Math.log(size) / Math.log(1024)).to_i
  if (exp > 6) then
    exp = 6
  end
  return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
end

class FindCommand
  def initialize
    @cmd = ["find"]
    @dirs = []
    @type = nil
    @predinames = []
    @prediregex = []
    @actions = []
  end

  def type(c)
    @type = c
  end

  def dir(*a)
    @dirs.push(*a)
  end

  def iname(*a)
    @predinames.push(*a)
  end

  def iregex(*rxes)
    rxes.each do |rx|
      @prediregex.push('.*/' + "#{rx}")
    end
  end

  def build
    haveiname = (@predinames.length > 0)
    haverx = (@prediregex.length > 0)
    cmd = ["find", *@dirs]
    if @type != nil then
      cmd.push("-type", @type)
    end
    if haverx then
      cmd.push("-regextype", "awk")    
    end
    if haveiname then
      @predinames.each_with_index do |iname, i|
        cmd.push("(", "-iname", iname, ")")
        if (i + 1) != @predinames.length then
          cmd.push("-o")
        end
      end
    end
    if haverx then
      @prediregex.each_with_index do |irx, i|
        cmd.push("(", "-iregex", irx, ")")
        if (i + 1) != @prediregex.length then
          cmd.push("-o")
        end
      end
    end
    $stderr.printf("build: %p\n", cmd)
    return cmd
  end

  def run(&b)
    cmd = build()
    Open3.popen2(*cmd) do |stdin, stdout, thr|
      stdout.each_line do |ln|
        #$stderr.printf("ln: %p\n", ln)
        ln = ln.slice(0, ln.length - 1)
        if ln[-1] == "\r" then
          ln = ln.slice(0, ln.length - 1)
        end
        #$stderr.printf("calling: %p\n", ln)
        b.call(ln)
      end
    end
  end
end

class FileFind
  def initialize(opts)
    @opts = opts
    @fc = FindCommand.new
    @onlyfiles = (@opts.onlyfiles == true)
    @onlydirs = (@opts.onlydirs == true)
    @patterns = @opts.patterns
    @asregex = (@opts.asregex == true)
    @ignorecase = (@opts.ignorecase == true)
    @delfiles = (@opts.deletefiles == true)
    @printsize = (@opts.printsize == true)
    @sortsize = (@opts.sortsize == true)
    @cache = {}
    if @asregex then
      #@patterns.map!{|pat| Regexp.new(pat, (@ignorecase ? "i" : nil)) }
    end
  end

  def ismatch_spregex(path, pat)
    if path.match?(pat) then
      return true
    end
    return false
  end

  def ismatch_spglob(path, pat)
    base = File.basename(path)
    return File.fnmatch(pat.scrub, base.scrub, (if @ignorecase then File::FNM_CASEFOLD else 0 end))
  end

  def ismatch_singlepattern(path, pat)
    if @asregex then
      return ismatch_spregex(path, pat)
    end
    return ismatch_spglob(path, pat)
  end

  def ismatch_patterns(path)
    @patterns.each do |pat|
      if ismatch_singlepattern(path, pat) then
        return true
      end
    end
    return false
  end

  def ismatch(path)
    if (@onlyfiles == true) && (File.file?(path) == false) then
      return false
    elsif (@onlydirs == true) && (not File.directory?(path) == false) then
      return false
    end
    if not @patterns.empty? then
      return ismatch_patterns(path)
    end
    return true
  end

  def getsize(path)
    sz = (
      begin
        File.size(path)
      rescue
        0
      end
    )
    return sz
  end

  def outsize(sz)
    $stdout.printf("%s\t", size_to_readable(sz))
  end

  def outwrite(path)
    sz = getsize(path)
    if @printsize && @sortsize then
      @cache[path] = sz
    else
      if @printsize then
        outsize(sz)
      end
      $stdout.puts(path)
      $stdout.flush
    end
  end

  def delfile(path)
    $stdout.printf("deleting %p ... ", path)
    begin
      File.delete(path)
    rescue => ex
      $stdout.printf("failed: (%s) %s", ex.class.name, ex.message)
    else
      $stdout.printf("ok")
    ensure
      $stdout.puts
    end
  end

  def oldmain(dirs)
    $stdout.sync = true
    if dirs.empty? then
      dirs.push(".")
    end
    Find.find(*dirs) do |path|
      if ismatch(path) then
        if @delfiles then
          delfile(path)
        else
          outwrite(path)
        end
      end
    end
    if @sortsize then
      @cache.sort_by{|_, sz| sz}.each do |path, sz|
        outsize(sz)
        $stdout.printf("%s\n", path)
        $stdout.flush
      end
    end
  end

  def main(dirs)
    fc = FindCommand.new
    fc.dir(*dirs)
    fc.type(
      if @opts.onlyfiles then
        'f'
      elsif @opts.onlydirs then
        'd'
      elsif @opts.onlylinks then
        'l'
      end
    )
    if @opts.asregex then
      fc.iregex(*@opts.patterns)
    else
      fc.iname(*@opts.patterns)
    end
    fc.run do |path|
      if ismatch(path) then
        if @delfiles then
          delfile(path)
        else
          outwrite(path)
        end
      end
    end
    if @sortsize then
      @cache.sort_by{|_, sz| sz}.each do |path, sz|
        outsize(sz)
        $stdout.printf("%s\n", path)
        $stdout.flush
      end
    end
  end
end

begin
  opts = OpenStruct.new({
    patterns: [],
    asregex: false,
    onlyfiles: false,
    onlydirs: false,
    ignorecase: false,
    printsize: false,
    sortsize: true,
  })
  OptionParser.new{|prs|
    prs.on("-p<pat>", "set pattern"){|s|
      opts.patterns.push(s)
    }
    prs.on("-c", "-i", "ignore case"){
      opts.ignorecase = true
    }
    prs.on("-r", "pattern is a regex"){
      opts.asregex = true
    }
    prs.on("-f", "only files"){
      opts.onlyfiles = true
    }
    prs.on("-d", "only directories"){
      opts.onlydirs = true
    }
    prs.on("-s", "--size", "print file sizes"){
      opts.printsize = true
    }
    prs.on("--delete", "delete files"){
      opts.deletefiles = true
    }
  }.parse!
  ff = FileFind.new(opts)
  ff.main(ARGV)
end

