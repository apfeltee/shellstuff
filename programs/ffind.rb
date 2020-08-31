#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "find"

class FileFind
  def initialize(opts)
    @opts = opts
    @onlyfiles = (@opts.onlyfiles == true)
    @onlydirs = (@opts.onlydirs == true)
    @patterns = @opts.patterns
    @asregex = (@opts.asregex == true)
    @ignorecase = (@opts.ignorecase == true)
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
    return File.fnmatch(pat, base, (@ignorecase ? File::FNM_CASEFOLD : 0))
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

  def outwrite(path)
    $stdout.puts(path)
    $stdout.flush
  end

  def main(dirs)
    if dirs.empty? then
      dirs.push(".")
    end
    Find.find(*dirs) do |path|
      if ismatch(path) then
        outwrite(path)
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
  }.parse!
  ff = FileFind.new(opts)
  ff.main(ARGV)
end

