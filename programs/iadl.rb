#!/usr/bin/ruby

require "optparse"
require "addressable/uri"

def do_dl(thing, iscollection)
  #exec("ia download --search collection:bplscinc")
  cmd = ["ia", "download", "--verbose"]
  if iscollection then
    cmd.push("--search", sprintf("collection:%s", thing))
  else
    cmd.push(thing)
  end
  system(*cmd)
end

def extract_name(url)
  u = Addressable::URI.parse(url)
  return u.path.split("/").map(&:strip).reject(&:empty?)[1]
end

begin
  iscol = false
  OptionParser.new{|prs|
    prs.on("-c", "--collection"){
      iscol = true
    }
  }.parse!
  if ARGV.empty? then
    printf("too few arguments\n")
    exit(1)
  else
    ARGV.each do |a|
      if a.match?(/\w+:\/\//) then
        do_dl(extract_name(a), iscol)
      else
        do_dl(a, iscol)
      end
    end
  end
end


