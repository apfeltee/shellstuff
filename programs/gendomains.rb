#!/usr/bin/ruby

# generate domain names

require "ostruct"
require "optparse"

begin
  dupes = []
  opts = OpenStruct.new({
    tlds: ["com", "net", "org"],
    hosts: [],
    scheme: "http",
    asurls: false,
  })
  OptionParser.new{|r|
    r.on("-t<s>", "--tld=<s>"){|v|
      ntlds = v.split(",").map(&:strip).reject(&:empty?)
      opts.tlds += ntlds
    }
    r.on("-s<s>", "--scheme=<s>"){|v|
      opts.scheme = s
    }
    r.on("-u", "--urls"){
      opts.asurls = true
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("usage: gendomains [-t tld,anothertld,...] <hostnames...>\n")
    exit(1)
  else
    ARGV.each do |a|
      opts.tlds.each do |tld|
        hn = sprintf("%s.%s", a, tld).downcase
        if not dupes.include?(hn) then
          dupes.push(hn)
          if opts.asurls then
            $stdout.printf("%s://%s/\n", opts.scheme, hn)
          else
            $stdout.printf("%s\n", hn)
          end
          $stdout.flush
        end
      end
    end
  end
end



