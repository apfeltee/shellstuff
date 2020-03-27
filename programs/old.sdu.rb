#!/usr/bin/ruby --disable-gems

require "optparse"
require "open3"

def pipe(cmda, cmdb)
  #$stderr.printf("pipe: cmda=%p cmdb=%p\n", cmda, cmdb)
  return Open3.pipeline(cmda, cmdb)
end

begin
  cmd_du = ["du", "-h"]
  cmd_sort = ["sort", "-h"]
  items = []
  ARGV.map!(&:scrub)
  (prs=OptionParser.new{|prs|
    prs.on("-r", "--reverse", "sort in reverse"){|_|
      cmd_sort.push("-r")
    }
    prs.on("-d<l>", "--depth=<l>", "descent at most <l> levels"){|v|
      cmd_du.push("-d#{v}")
    }
    prs.on("-c", "-s", "--summary", "also print summary (useful for multiple files)"){
      cmd_du.push("-c")
    }
  }).parse!
  
  begin
    hasdirs = false
    if ARGV.empty? then
      #cmd_du.push("-d0", "--", *Dir.glob("*"))
      items = Dir.glob("*")
    else
      items = ARGV
    end
    items.map! do |item|
      if File.directory?(item) then
        hasdirs = true
        next item = item + "/"
      else
        next item
      end
    end
    cmd_du.push("-d0") if hasdirs
    cmd_du.push("--", *items)
  ensure
    pipe(cmd_du, cmd_sort)
  end
end

