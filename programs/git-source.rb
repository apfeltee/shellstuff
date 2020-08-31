#!/usr/bin/ruby
=begin
also: grep -P '^\s*\bur(l|i)\b\s*=' $dir/.git/config
but why make it easy, when you can make it difficult?
=end
require "ostruct"
require "optparse"

def fail(*a, **kw)
  $stderr.printf("error: %s\n", sprintf(*a, **kw))
  return 1
end

# dumb, probably error-prone ini parser:
#> $data is Hash
#> $section is String = "main"
#> go $line by $line
#> if $line is like "[<name:string>]", then section = $name
#> elsif $line is like "<key:string> = <value:string>" then $data[$section][$name] = $value
#> else complain about $line
#> return $data
# that's all it does.
def parse(file)
  data = Hash.new{}
  lines = File.readlines(file)
  section = "main"
  lines.each.with_index do |line, lno|
    line.strip!
    next if (line.empty? || line.match?(/^#/))
    if (m = line.match(/^\[\s*(?<name>[\w\s\"\'\.]+)\s*\]/)) != nil then
      section = m["name"].strip
    elsif (m = line.match(/^(?<key>[\w\.]+)\s*\=\s*(?<val>.+)(\s*#.*)?/)) != nil then
        if not data.key?(section) then
          data[section] = {}
        end
        data[section][m["key"].strip] = m["val"].strip
    else
      $stderr.printf("WARNING: in %p: near line %d: unexpected line %p\n", file, lno+1, line)
    end
  end
  return data
end

def findremote(confdata)
  confdata.each do |sectionname, data|
    # git can have several remotes, but eh.
    if sectionname.downcase.match?(/^remote\s*/) then
      return data["url"]
    end
  end
  return nil
end

def modify(remote, opts)
  isgitssh = remote.match?(/^git@/)
  ishttp = remote.match?(/^https?:\/\//)
  if isgitssh || ishttp then
    if opts.asuri then
      if ishttp then
        return remote
      else
        return remote.gsub(":", "/").gsub(/^git@/, "https://")
      end
    else
      return remote
    end
  end
  return nil
end

def gitsource(dir, opts)
  gitdir = File.join(dir, ".git")
  return fail("not a git directory: %p", dir) unless File.directory?(gitdir) 
  configfile = File.join(gitdir, "config")
  return fail(".git/config not found in %p", dir) unless File.file?(configfile)
  confdata = parse(configfile)
  remote = findremote(confdata)
  return fail("failed to find 'url' from section matching [remote ...] from %p", configfile) if (remote == nil)
  finalstr = modify(remote, opts)
  return fail("failed to (de)parse remote uri %p from %p", remote, configfile) if (finalstr == nil)
  puts(finalstr)
  return 0
end

begin
  opts = OpenStruct.new({
    asuri: false,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-u", "--uri", "extract remote uri as http url"){
      opts.asuri = true
    }
  }.parse!
  rc = 0
  if ARGV.empty? then
    rc += gitsource(".", opts)
  else
    ARGV.each do |arg|
      rc += gitsource(arg, opts)
    end
  end
  exit(rc > 0 ? 1 : 0)
end

