#!/usr/bin/ruby

## parses raw mail, i.e., .eml files
## try selecting 'original message' in google mail, and/or whatever dumb mail host you use

require "ostruct"
require "optparse"
require "mail"
require "pry-byebug"

class ParseMailProgram

  VALIDFIELDS = %w(
    envelope_from
    from
    sender
    to
    cc
    subject
    date
    message_id
    body
  )

  DEFAULTFIELDS = %w(
    envelope_from from sender to cc message_id subject
  )

  def initialize(opts)
    @opts = opts
    @parser = nil
    @wantfields = @opts.wantfields
  end

  def getfield(field)
    begin
      if field == "from" then
        #return @parser.from.addresses
        return @parser.from
      elsif field == "sender" then
        return @parser.sender
      elsif field == "envelope" then
        return @parser.envelope_from
      else
        return @parser.send(field)
      end
    rescue NoMethodError
      return nil
    end
  end

  def parse(str)
    @parser = Mail.read_from_string(str.scrub)
    #binding.pry
    return self
  end

  def print_out
    @wantfields.each do |field|
      val = getfield(field)
      if val != nil then
        $stdout.printf("%-32s: %s\n", field, val.to_s)
      end
    end
  end
end

def pmp(argv, opts, &b)
  prog = ParseMailProgram.new(opts)
  if argv.empty? then
    if $stdin.tty? then
      $stderr.printf("error: nothing piped and no arguments\n")
    else
      b.call(prog.parse($stdin.read))
    end
  else
    argv.each do |file|
      b.call(prog.parse(File.read(file)))
    end
  end
end

begin
  opts = OpenStruct.new({
    wantfields: [],
  })
  OptionParser.new{|prs|
    prs.on("-f<field>", "--field=<field>", "print only <field> (specified multiple times, or separated by comma)"){|v|
      v.split(",").map(&:strip).map(&:downcase).reject(&:empty?).each do |field|
        opts.wantfields.push(field) unless opts.wantfields.include?(field)
      end
    }
  }.parse!
  if opts.wantfields.empty? then
    opts.wantfields = ParseMailProgram::DEFAULTFIELDS
  end
  pmp(ARGV, opts) do |prog|
    prog.print_out
  end
end

