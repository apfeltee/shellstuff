#!/usr/bin/ruby

require "ostruct"
require "optparse"

def run_ctags(files)
  exec("ctags", "-x", "--c-kinds=v", "--file-scope=yes", "--output-format=xref", *files)
  #exec("ctags", "-x", "--c-kinds=v", "--file-scope=no", *files)
end

def run_clangquery(files)
  query = 'match varDecl(hasGlobalStorage())'
  exec("clang-query", "-c", query, *files)
end

begin
  useclang = false
  OptionParser.new{|prs|
    prs.on("-q"){
      useclang = true
    }
  }.parse!
  files = ARGV
  if !useclang then
    run_ctags(files)
  else
    run_clangquery(files)
  end
end
