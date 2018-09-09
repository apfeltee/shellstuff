#!/usr/bin/ruby

require "filemagic"
require_relative File.join(ENV["HOME"], "/dev/gems/srcwalk/lib/srcwalk")
require_relative File.join(ENV["HOME"], "/dev/gems/spinner/lib/spinner")



def counttypes(directory)
  types = {}
  print("[counttypes] collecting files ... ")
  SourceWalk::walk(directory, verbose: false) do |path, finished, i|
    FileMagic.open do |magic|
      begin
        if not finished then
          Spinner::spin
        else
          puts
        end
  
        # raw = don't translate potentially untranslatable characters to an \ooo notation
        # continue = don't just stop at the first match, but continue if possible (what the 'file' command does)
        # mime = return the mime type only. if the description is needed instead, just remove this bit
        magic.flags = [:raw, :continue, :mime]
        mime = magic.file(path)
        # cleanup mime string (for descriptions)
        if mime.match(/\n/) then
          mime = mime.split(/\n/)[0]
        end
        # next, add it to the hashmap
        if types[mime] == nil then
          types[mime] = [path]
        else
          types[mime] << path
        end
        magic.close
      rescue FileMagic::FileMagicError => err
        puts "error: #{path.inspect}: #{err}"
      end

    end
  end
  types.sort_by{|mime, files| files.size}.each do |mime, files|
    #printf("  %-15d  %s\n", files.size, mime)
    printf("  %-15s %d:\n", mime, files.size)
    files.each do |path|
      puts("    #{path}\n")
    end
  end
end

$stdout.sync = true
(if ARGV.length > 0 then ARGV else ["."] end).each{|d| counttypes(d) }
