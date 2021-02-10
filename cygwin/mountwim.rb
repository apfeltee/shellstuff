#!/usr/bin/ruby

require "ostruct"
require "fileutils"
require "optparse"

# DISM /Mount-image /imagefile:<path_to_Image_file> {/Index:<image_index> | /Name:<image_name>} /MountDir:<target_mount_directory> [/readonly] /[optimize]}

def cygpath(itm)
  return IO.popen(["cygpath", "-wa", itm]){|io| io.read }.strip
end

def mountwim(file, dir, opts)
  dismexe = "c:/windows/system32/dism.exe"
  winfile = cygpath(file)
  windir = cygpath(dir)
  if not File.directory?(windir) then
    FileUtils.mkdir_p(windir)
  end
  cmd = [dismexe, "/mount-image", "/imagefile:#{winfile}", "/mountdir:#{windir}"]
  cmd.push("/index:#{opts.index}") if (opts.index != nil)
  cmd.push("/name:#{opts.name}") if (opts.name != nil)
  cmd.push("/optimize") if opts.optimize
  cmd.push("/readonly") if opts.readonly
  $stderr.printf("command: %s\n", cmd.map{|s| s.dump.gsub(/\\"/, '"') }.join(" "))
  exec(*cmd)
end

def do_unmount(dir, opts)
  windir = cygpath(dir)
  cmd = ["c:/windows/system32/dism.exe", "/Unmount-image", "/MountDir:#{windir}"]
  if opts.commit then
    cmd.push("/commit")
  else
    cmd.push("/discard")
  end
  system(*cmd)
end

begin
  opts = OpenStruct.new({
    index: nil,
    name: nil,
    optimize: false,
    readonly: true,
    unmount: false,
    commit: false,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help"){
      puts(prs.help)
      exit
    }
    prs.on("-w", "--readwrite"){
      opts.readonly = false
    }
    prs.on("-o", "--optimize"){
      opts.optimize = true
    }
    prs.on("-i<val>", "--index=<val>"){|v|
      opts.index = v.to_i
    }
    prs.on("-n<val>", "--name=<val>"){|v|
      opts.name = v
    }
    prs.on("-u", "--unmount"){
      opts.unmount = true
    }
    prs.on("-c", "--commit"){
      opts.commit = true
    }
  }.parse!
  if opts.unmount then
    ARGV.each do |dir|
      do_unmount(dir, opts)
    end
  else
    file = ARGV.shift
    if file == nil then
      $stderr.printf("usage: mountwim <wimfile> [<directory>]\n")
      exit(1)
    else
      if (opts.index == nil) && (opts.name == nil) then
        $stderr.printf("error: must supply --index=<index> or --name=<name>\n")
        exit(1)
      end
      if not file.match?(/\.wim$/i) then
        $stderr.printf("error: dism will likely fail if the image file extension is not '.wim'!\n")
        exit(1)
      end
      destdir = ARGV.shift
      if destdir == nil then
        bs = File.basename(file).gsub(/\.\w+$/i, "").strip.downcase
        destdir = sprintf("c:/shared/%s", bs)
      end
      mountwim(file, destdir, opts)
    end
  end
end

