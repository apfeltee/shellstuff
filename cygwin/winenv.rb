#!/usr/bin/ruby --disable-gems

require "win32ole"

# the default user to choose?
DEFAULT_USER = "USER"

# winshell ref
$wshell = WIN32OLE.new("wscript.shell")

def process_key(key)
  if key.match(/%[a-zA-Z0-9_]+%/) then
    return $wshell.ExpandEnvironmentStrings(key)
  end
  return key
end

def get_env_from(user)
  return $wshell.Environment(user)
end

def list_env
  users = %w(PROCESS SYSTEM USER VOLATILE)
  users.each do |user|
    puts("environment(#{user}):")
    get_env_from(user).each do |val|
      parts = val.split(/=/)
      key = parts.shift
      val = process_key(parts.join("="))
      keyfmt = sprintf("%-25s", key)
      puts("  #{keyfmt} = #{val.inspect}")
    end
  end
end

if ARGV.length > 0 then
  # when processing ARGV, don't use get_env_from, because it
  # distinguishes between classes!
  puts(process_key($wshell.Environment[ARGV.first]))
else
  list_env
end
