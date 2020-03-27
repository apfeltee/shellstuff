#!/usr/bin/ruby

require "ostruct"
require "optparse"

def posix_size_format(size)
  units = ['B', 'K', 'M', 'G', 'T', 'P', 'E']
  if size == 0 then
    return '0B'
  end
  exp = (Math.log(size) / Math.log(1024)).to_i
  if exp > 6 then
    exp = 6
  end
  return sprintf('%.1f%s', (size.to_f / (1024 ** exp)), units[exp])
end

def filesize(path)
  begin
    return File.size(path)
  rescue => e
    $stderr.printf("warning: cannot read %p: (%s) %s\n", path, ex.class.name, ex.message)
    return 0
  end
end

def dutotal(files)
  totalsz = 0
  files.each do |item|
    if File.file?(item) then
      totalsz += filesize(item)
    end
  end
  yield totalsz
end

def main(files)
  dutotal(files) do |sz|
    puts(posix_size_format(sz))
  end
end

begin
  $stdout.sync = true
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
  }.parse!
  if ARGV.empty? then
    if $stdin.tty? then
      $stderr.puts("error: nothing piped, and no files specified")
    else
      main($stdin.readlines.map(&:strip).reject(&:empty?))
    end
  else
    main(ARGV)
  end
end