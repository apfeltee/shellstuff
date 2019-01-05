#!/usr/bin/ruby

require "optparse"

def handle_code(code, cmd)
  if code == 0 then
    $stderr.printf("command ran successfully\n")
  else
    $stderr.printf("command failed with statusd %d\n", code)
    $stderr.printf("command: %p\n", cmd)
  end
end

def delete_acls(destfiles, moreopts)
  cmd = ["setfacl", "-b", *destfiles]
  IO.popen(*cmd) do |io|
    io.close
    handle_code($?, cmd)
  end
end

def copy_permission_text(permtext, destfiles, moreopts)
  cmd = ["setfacl", "-f-", *moreopts, *destfiles]
  IO.popen(*cmd) do |io|
    io.write(permtext)
    io.close
    handle_code($?, cmd)
  end
end

def copy_permission_file(srcfile, destfiles, moreopts)
  cmd = ["getfacl", srcfile]
  IO.popen(*cmd) do |io|
    copy_permission_text(io.read, moreopts, destfiles)
    io.close
    handle_code($?, cmd)
  end
end

begin
  want_delete = false
  moreopts = []
  OptionParser.new{|prs|
    prs.on("-k", "--delete-acls"){|_|
      want_delete = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("error: too few arguments\n")
    exit(1)
  else
    if want_delete then
      delete_acls(ARGV, moreopts)
    else
      if $stdin.tty? then
        srcfile = ARGV.shift
        destfiles = ARGV
        if (srcfile == nil) || (destfiles.empty?) then
          $stderr.printf("error: first argument is permissions source file, rest are destination files\n")
          exit(1)
        else
          copy_permission_file(srcfile, destfiles, moreopts)
        end
      else
        permtext = $stdin.read.strip
        if permtext.empty? then
          $stderr.printf("error: permission rules from stdin is empty\n")
          exit(1)
        end
        copy_permission_text(permtext, ARGV, moreopts)
      end
    end
  end
end

