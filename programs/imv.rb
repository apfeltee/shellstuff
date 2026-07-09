#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "readline"

## stupid retarded hack because ruby3 uses reline to silently remap readline
$dllfiles = ["readline.so", "readline.dll"]
$actualreadline = false
$dllfiles.each do |file|
  begin
    require file
    $actualreadline = true
    break
  rescue 
  end
end
if !$actualreadline then
  $stderr.printf("YOU DO NOT HAVE 'readline-ext' INSTALLED! imv WILL NOT BEHAVE AS INTENDED!\n")
  $stderr.printf("try running: [sudo] gem install readline-ext\n")
end


### end retarded hack

class IMV

  def initialize(opts)
    @opts = opts
  end

  def readinput(basename, autotext)
    if @opts.set_beginning then
      Readline.pre_input_hook = -> do
        Readline.insert_text(autotext)
        Readline.redisplay
        # Remove the hook right away.
        Readline.pre_input_hook = nil
      end
    end

    rd = Readline.readline(sprintf("%p: ", basename))

    return rd
  end

  def do_preview_data(chunk)
    # should be an option ...
    maxlen = 80
    lno = 1
    ci = 0
    $stdout.printf("preview:\n")
    $stdout.printf(" %03d  ", lno)
    while (ci < chunk.length) do
      thisci = ci
      thisline = lno
      ci += 1
      endline = false
      ch = chunk[thisci]
      dqs = ch.dump[1 .. -2]
      $stdout.write(dqs)
      if ch == "\n" then
        endline = true
        lno += 1
        $stdout.write("\n")
        $stdout.printf(" %03d  ", lno)
        $stdout.flush
      end
    end
    $stdout.write("\n")
  end

  def do_preview_directory(path)
    system("ls", "-l", path)
  end

  def do_preview_file(path)
    begin
      File.open(path, "rb") do |fh|
        chunk = fh.read(@opts.previewchunksize)
        do_preview_data(chunk)
      end
    rescue => ex
      $stderr.printf("**error: cannot preview %p: (%s) %s\n", path, ex.class.name, ex.message)
    end
  end

  def do_preview(path)
    if File.directory?(path) then
      do_preview_directory(path)
    else
      do_preview_file(path)
    end
  end

  def do_rename(path)
    dir = File.dirname(path)
    basename = File.basename(path)
    ext = File.extname(basename)
    stem = File.basename(basename, ext)
    if @opts.dopreview then
      do_preview(path)
    end
    Dir.chdir(dir) do
      while true do
        autotext = nil
        if @opts.prefill then
          autotext = basename
          if @opts.defpath then
            autotext = File.join(@opts.defpath, basename)
          end
        end
        $stderr.printf("autotext=%p\n", autotext)
        rd = readinput(basename, autotext).strip
        if (rd == "") then
          #$stderr.printf("empty input. try again, or press ^C\n")
          #next
          return
        end
        if rd != basename then
          if File.exist?(rd) then
            $stderr.printf("cannot rename %p to %p because %p already exists", basename, rd, basename)
            return
          end
          $stderr.printf("renaming %p to %p\n", basename, rd)
          File.rename(basename, rd)
          return
        else
          return
        end
      end
    end
  end

  def handle(arg)
    rt = 0
    if File.exist?(arg) then
      if File.file?(arg) || File.directory?(arg) || File.symlink?(arg) then
        if (@opts.skipdirs && File.directory?(arg)) then
          return
        end
        do_rename(arg)
      else
        $stderr.printf("imv: error: %p is neither file nor directory nor symlink\n", arg)
        rt += 1
      end
    else
      $stderr.printf("imv: error: %p does not exist\n", arg)
      rt += 1
    end
    return rt
  end

end

begin
  rt = 0
  prog = File.basename($0)
  opts = OpenStruct.new({
    prefill: true,
    skipdirs: false,
    set_beginning: false,
    patsubs: [],
    dopreview: false,
    previewchunksize: 512,
    defpath: nil,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "print this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-d", "--skipdirs", "when globbing args to #{prog}, skip args that are directories"){
      opts.skipdirs = true
    }
    prs.on("-g<pat>", "-e<pat>", "--gsub=<pat>", "automatically rename using regex pattern pat"){|s|
      opts.patsubs.push(s)
    }
    prs.on("-x", "--nofill", "do not pre-fill input"){
      opts.prefill = false
    }
    prs.on("-b", "--beginning", "set cursor to the start of the given path name"){
      opts.set_beginning = true
    }
    prs.on("-v", "--preview", "also preview file input"){
      opts.dopreview = true
    }
    prs.on("-c<n>", "--chunksize=<n>", "set chunk size for preview"){|v|
      opts.previewchunksize = v.to_i
    }
    prs.on("-d<dir>", "--defaultpath=<dir>", "prefill prompt with default path <dir>"){|v|
      opts.defpath = v
    }
  }.parse!
  imv = IMV.new(opts)
  if ARGV.empty? then
    $stderr.printf("missing arguments! try: %s --help\n", prog)
    exit(1)
  else
    ARGV.each do |arg|
      rt += imv.handle(arg)
    end
    exit(if rt > 0 then 1 else 0 end)
  end
end

