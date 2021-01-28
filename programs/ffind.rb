#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "find"

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

class FileFind
  def initialize(opts)
    @opts = opts
    @onlyfiles = (@opts.onlyfiles == true)
    @onlydirs = (@opts.onlydirs == true)
    @patterns = @opts.patterns
    @asregex = (@opts.asregex == true)
    @ignorecase = (@opts.ignorecase == true)
    @delfiles = (@opts.deletefiles == true)
    @printsize = (@opts.printsize == true)
    if @asregex then
      @patterns.map!{|pat| Regexp.new(pat, (@ignorecase ? "i" : nil)) }
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

  def outsize(path)
    sz = (
      begin
        File.size(path)
      rescue
        0
      end
    )
    $stdout.printf("%s\t", size_to_readable(sz))
  end

  def outwrite(path)
    if @printsize then
      outsize(path)
    end
    $stdout.puts(path)
    $stdout.flush
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

  def main(dirs)
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

