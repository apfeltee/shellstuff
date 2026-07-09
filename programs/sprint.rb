#!/usr/bin/ruby

require "ostruct"
require "optparse"

module CType
  def self.isprint(b)
    return ((b >= 040) && (b < 0177))
  end

  def self.isdigit(b)
    return ((b <= '9'.ord) && (b >= '0'.ord))
  end

  def self.isspace(b)
    return ((b == 32) || (b == 9) || (b == 13) || (b == 10) || (b == 12))
  end

  def self.isascii(b)
    return ((b < 0200) && (b >= 0))
  end

  def self.isupper(c)
    return ((c <= 'Z'.ord) && (c >= 'A'.ord))
  end

  def self.islower(c)
    return ((c <= 'z'.ord) && ( c >= 'a'.ord))
  end

  def self.isalpha(c)
    return (isupper(c) || islower(c))
  end

  def self.isalnum(c)
    return (isalpha(c) || isdigit(c))
  end


  #define iscntrl(c) (((c) < 040 || (c) == 0177) && isascii((c)))
  #define ispunct(c) (!isalnum((c)) && isprint(c))
  #define toupper(c) (islower((c)) ? (c) & ~32 : (c))
  #define tolower(c) (isupper((c)) ? (c) | 32 : (c))
  #define toascii(c) ((c) & 0177)

end

class AcceptableChar
  def initialize(modes)
    @mappings = []
    if modes != nil then
      if modes.length > 0 then
        cmodes = modes.split(",").map(&:strip).reject(&:empty?).map(&:downcase)
        cmodes.each do |mode|
          mthname = "is#{mode}"
          if mode.start_with?("is") then
            mthname = mode
          end
          if CType.respond_to?(mthname) then
            @mappings.push(CType.method(mthname))
          end
        end
      end
    end
    @maplength = @mappings.length
  end

  def acceptable(byte)
    if @maplength == 0 then
      return true
    end
    ocode = 0
    @mappings.each do |mth|
      if mth.call(byte) then
        ocode += 1
      end
    end
    if ocode == 0 then
      return false
    end
    return true
  end
end

def do_io(fh, opts)
  ofile = opts.ofile
  wt = opts.waittime
  linelen = 0
  sentinel = nil
  if opts.acceptabletypes != nil then
    sentinel = AcceptableChar.new(opts.acceptabletypes)
  end
  fh.each_byte do |bt|
    if sentinel != nil then
      if !sentinel.acceptable(bt) then
        next
      end
    end
    ch = bt.chr rescue 0
    ofile.write(ch)
    ofile.flush
    linelen += 1
    if opts.limitlinelength then
      if linelen >= opts.maxlinelength then
        ofile.write("\n")
        ofile.flush
        linelen = 0
      end
    end
    if wt > 0.0 then
      sleep(wt)
    end
  end
end

def do_file(path, opts)
  begin
    File.open(path, "rb") do |fh|
      begin
        do_io(fh, opts)
      rescue Interrupt
      end
    end
    return true
  rescue => ex
    $stderr.printf("sprint: failed to open %p for reading: (%s) %s\n", path, ex.class.name, ex.message)
  end
  return false
end

begin
  rc = 0
  opts = OpenStruct.new({
    ofile: $stdout,
    waittime: 0.0,
    limitlinelength: false,
    maxlinelength: 0,
    acceptabletypes: nil,
  })
  OptionParser.new{|prs|
    # TODO: calculate miroseconds properly. very broken atm
    prs.on("-t<n>", "--wait=<n>", "--sleep=<n>", "wait n microseconds between each call to write()"){|v|
      opts.waittime = (v.to_f / (100 * 10))
      $stderr.printf("v.to_f=%p, waittime=%p\n", v.to_f, opts.waittime)
      #exit
    }
    prs.on("-p<modes>", "--only=<modes>", "only print bytes matching is<mode>(), i.e., `-pdigit,alpha` requires isdigit() and isalpha() to be true"){|s|
      opts.acceptabletypes = s
    }
    prs.on("-l<n>", "--maxlinelength=<n>", "split text into pseudo-lines of length <n>"){|v|
      opts.limitlinelength = true
      opts.maxlinelength = v.to_i
    }
  }.parse!
  if ARGV.empty? then
    do_io($stdin)
  else
    ARGV.each do |arg|
      ec = 0
      ec = do_file(arg, opts)
      rc += (ec ? 0 : 1)
    end
  end
  exit(rc == 0)
end