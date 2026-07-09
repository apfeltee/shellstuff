#!/usr/bin/ruby

begin
  exec("gs", "-sDEVICE=txtwrite", "-sOutputFile=-", "-q", "-dNOPAUSE", "-dBATCH", *ARGV)
end

