#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "find"

module Util

  def self.size_to_readable(size)
    units = ['B', 'K', 'M', 'G', 'T', 'P', 'E']
    if (size == 0) then
      return '0B'
    end
    exp = (Math.log(size) / Math.log(1024)).to_i
    if (exp > 6) then
      exp = 6
    end
    return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
  end

  def self.get_directory_size_extern(path)
    IO.popen(["du", "-bd0", path], "rb") do |io|
      return io.read.split(/\t/)[0].to_i
    end
  end

  def self.get_directory_size_ruby(path)
    sz = 0
    Find.find(path) do |path|
      next unless File.file?(path)
      sz += FileTest.size(path)
    end
    return sz
  end

  def self.get_directory_size(path)
    return self.get_directory_size_ruby(path)
  end

end

class SortedDU
  def initialize(opts)
    @opts = opts
    @totalsz = 0
    @items = []
  end

  def get_size_string(sz)
    if @opts.printbytes then
      return sz.to_s
    end
    return Util.size_to_readable(sz)
  end

  def get_dir_size(path)
    if @opts.usedu then
      return Util.get_directory_size_extern(path)
    end
    return Util.get_directory_size_ruby(path)
  end

  def add(name, path, justafile=false)
    #$stderr.printf("add(%p, %p)\n", name, path)
    if (@opts.globpattern != nil) then
      if not File.fnmatch(@opts.globpattern, name, File::FNM_CASEFOLD) then
        return
      end
    end
    begin
      sz = File.stat(path).size
      if (not justafile) && File.directory?(path) then
        sz = get_dir_size(path)
      end
      ###
      ### todo: fix recursion!
      ###
      data = {size: sz, name: name, path: path}
      if not @items.include?(data) then
        @totalsz += sz
        @items.push(data)
      end
    rescue => ex
      $stderr.printf("ERROR: cannot stat %p ((%s) %s)\n", path, ex.class.name, ex.message)
    end
  end

  def xsearch(dir, &b)
    #Find.find(dir) do |path|
    Dir.foreach(dir) do |name|
      next if ((name == ".") || (name == ".."))
      path = File.join(dir, name)
      if File.directory?(path) then
        path += "/"
      end
      b.call(name, path)
    end
  end

  def recsearch(dir)
    Find.find(dir) do |path|
      next if not File.file?(path)
      base = File.basename(path)
      add(base, path)
    end
  end

  def search(dir)
    xsearch(dir) do |name, path|
      if @opts.recursive && File.directory?(path) then
        recsearch(dir)
      else
        add(name, path)
      end
    end
  end

  def globpats(pat)
    if @opts.recursive then
      globrecursive(pat)
    else
      xsearch()
    end
  end

  def printout(szstr, item)
    $stdout.printf("%s\t%s\n", szstr, item)
    $stdout.flush
  end

  def printall
    sorted = @items.sort_by{|itm| itm[:size] }
    (@opts.reverse ? sorted.reverse : sorted).each do |item|
      szh = get_size_string(item[:size])
      name = item[:path]
      printout(szh, name)
    end
    if @opts.summary then
      szh = get_size_string(@totalsz)
      printout(szh, "total")
    end
  end

end

begin
  opts = OpenStruct.new({})
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-s", "--summary", "print summary"){
      opts.summary = true
    }
    prs.on("-r", "--reverse", "print results in reverse"){
      opts.reverse = true
    }
    prs.on("-x", "--recursive", "walk directories recursively"){
      opts.recursive = true
    }
    prs.on("-n", "--native", "use 'du' to determine directory size"){
      opts.usedu = true
    }
    prs.on("-g<pattern>", "--glob=<pattern>", "search for glob <pattern>"){|str|
      opts.globpattern = str
    }
    prs.on("-i", "--stdin", "also read paths from stdin"){
      opts.readstdin = true
    }
  }.parse!
  sdu = SortedDU.new(opts)
  begin
    args = ARGV
    ##
    ## outline:
    ## only implicitly add "." if argv empty AND not reading from stdin
    ##
    if opts.readstdin then
      $stdin.each_line do |ln|
        ln.strip!
        next if ln.empty?
        sdu.add(File.basename(ln), ln, true)
      end
    else
      if args.empty? then
        args.push(".")
      end
    end
    if (args.empty?) && (not opts.readstdin) then
      $stderr.printf("no arguments given - try '--help'\n")
      exit(1)
    end
    if not args.empty? then
      args.each do |arg|
        if File.exist?(arg) then
          if File.directory?(arg) then
            sdu.search(arg)
          else
            sdu.add(File.basename(arg), arg)
          end
        else
          $stderr.printf("ERROR: not a file/directory: %p\n", arg)
        end
      end
    end
  ensure
    sdu.printall
  end
end
