#!/usr/bin/ruby

=begin
https://github.com/rxi/aria
git@github.com:rxi/aria.git
=end

begin
  ARGV.each do |u|
    system("git", "clone", u)
  end
end