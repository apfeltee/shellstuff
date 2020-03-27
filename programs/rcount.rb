#!/usr/bin/ruby

require "ostruct"
require "optparse"

class RCount
  def initialize(opts)
    @opts = opts
    @items = Hash.new{|selfhash, key| selfhash[key] = 0 }
  end

  def main(io)
    io.each_line(@opts.linesep) do |line|
      fields = line.split(@opts.separator)
      rstr = fields[@opts.field]
      if (rstr != nil) then
        if @opts.stripstring then
          rstr.strip!
        end
        if not rstr.empty? then
          @items[rstr] += 1
        end
      end
    end
  end

  def printresults
    items = @items.sort_by{|str, count| count}
    if @opts.reverse then
      items.reverse!
    end
    items.each do |str, cnt|
      $stdout.printf("%d\t%s\n", cnt, str)
    end
  end
end 

begin
  opts = OpenStruct.new({
    separator: "\t",
    linesep: "\n",
    field: nil,
    stripstring: true,
  })
  OptionParser.new{|prs|
    prs.on("-d<val>", "--delimiter=<val>"){|v|
      opts.separator = v
    }
    prs.on("-f<n>", "--field=<n>"){|v|
      opts.field = v.to_i
    }
  }.parse!
  rc = RCount.new(opts)
  begin
    if opts.field == nil then
      $stderr.printf("error: must specify field via -f\n")
      exit(1)
    end
    if opts.separator == "" then
      $stderr.printf("error: separator cannot be empty\n")
      exit(1)
    end
    if ARGV.empty? then
      rc.main($stdin)
    else
      ARGV.each do |arg|
        begin
          File.open(arg, "rb") do |fh|
            rc.main(fh)
          end
        rescue => ex
          $stderr.printf("error: could not open %p: (%s) %s\n", arg, ex.class.name, ex.message)
        end
      end
    end
  ensure
    rc.printresults()
  end
end
