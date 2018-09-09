#!/usr/bin/ruby --disable-gems

require "optparse"
require "win32ole"

module COMGUI
  WShell = WIN32OLE.new("WScript.Shell")

  def self.messagebox(title: "No Title", message: "Default message", icons: 64, seconds: 0)
    return WShell.Popup(message, seconds, title, icons)
  end
end

begin
  args = {}
  prs = OptionParser.new{|prs|
    prs.on("-t<str>", "--title=<str>", "set title (caption) to <str>"){|v|
      args[:title] = v
    }
    prs.on("-i<val>", "--icons=<val>", "set icon spec to <val> (must be numeric!)"){|v|
      args[:icons] = v.to_i
    }
    prs.on("-s<val>", "--seconds=<val>", "autoclose after <val> seconds. stays open by default"){|v|
      args[:seconds] = v.to_i
    }
  }
  prs.parse!
  if ARGV.empty? then
    puts(prs.help)
    exit(1)
  else
    args[:message] = ARGV.join(" ")
    COMGUI.messagebox(args)
  end
end
