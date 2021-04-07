#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "http"
require "oj"

def get(url)
  r = HTTP.follow(true).get(url)
  return r.body.to_s
end

class GetGithubRepos
  def initialize(opts, accpoint, username)
    @opts = opts
    @url = sprintf(accpoint, username: username)
    if opts.perpage then
      @url += "?per_page=#{opts.perpage}"
    end
    @body = get(@url)
    @json = Oj.load(@body)
  end

  def printrepo(repo)
    giturl = repo["git_url"]
    $stdout.printf("%s\n", giturl)
    $stdout.flush
  end

  def printresults
    @json.each do |repo|
      printrepo(repo)
    end
  end
end

begin
  accpoint = "https://api.github.com/users/%{username}/repos"
  opts = OpenStruct.new({
    perpage: nil,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-l<n>", "--limit=<n>", "limit results to <n> entries"){|v|
      opts.perpage = v.to_i
    }
  }.parse!
  if ARGV.empty? then
    $stderr.printf("too few arguments; expected a username.\n")
    exit(1)
  else
    ARGV.each do |a|
      GetGithubRepos.new(opts, accpoint, a).printresults
    end
  end
end


