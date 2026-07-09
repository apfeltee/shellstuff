#!/usr/bin/ruby

=begin
print the path in relation to a start directory.
i.e., if in a directory named "/home/blah/blurb/doop/gonk":
$ relname ../../ .
doop/gonk

... in other words, it prints "doop/gonk", since it's relative to "../../",
which would be "/home/blah/blurb".

(this is just a cli wrap for Pathname#relative_path_from. no need to reinvent the wheel)
=end

require "ostruct"
require "optparse"
require "pathname"

def get_relative(startdir, path)
  
  begin
    destp = Pathname.new(path)
    return destp.relative_path_from(startdir).to_s
  rescue => ex
    $stderr.printf("error: (%s) %s\n", ex.class.name, ex.message)
  end
  return nil
end


begin
  opts = OpenStruct.new({
    force: false,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help"){
      puts(prs.help)
      exit(1)
    }
    prs.on("-f", "--force"){
      opts.force = true
    }
  }.parse!
  startdir = ARGV.shift
  if ((startdir == nil) || ARGV.empty?) then
    $stderr.printf("need a start dir, and path arguments\n")
    exit(1)
  else
    fullstartdir = File.absolute_path(startdir)
    ec = 0
    ARGV.each do |path|
      fullpath = File.absolute_path(path)
      r = get_relative(fullstartdir, fullpath)
      if r == nil then
        ec += 1
      else
        $stdout.printf("%s\n", r)
      end
    end
    exit(ec > 0 ? 1 : 0)
  end
end

