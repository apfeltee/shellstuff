#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "shellwords"
require "~/dev/gems/lib/cygpath.rb"

ICACLS_EXE = "c:/windows/system32/icacls.exe"

DEFAULTOPTIONS = OpenStruct.new(

)

class BuildICCommand
  def initialize
    
end

class WinACL
  def initialize(opts, items)
    @opts = OpenStruct.new(DEFAULTOPTIONS.to_h.merge(opts.to_h))
    @items = items.map{|it| Cygpath.cyg2win(File.absolute_path(it)) }
    @command = [ICACLS_EXE]
  end

  def run
    $stderr.printf("command: %s\n", @command.map(&:dump).join("   \n"))
  end
end

begin
  opts = OpenStruct.new()
  (prs=OptionParser.new{|prs|
    
  }).parse!
  if ARGV.empty? then
    puts(prs.help)
    exit(1)
  else
    wacl = WinACL.new(opts, ARGV)
    wacl.run
  end
end


