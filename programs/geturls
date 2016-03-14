#!/usr/bin/ruby

require 'uri'

URI.extract($stdin.read, %w(http https ftp)) do |url|
  puts url
end
