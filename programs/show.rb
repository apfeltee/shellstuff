#!/usr/bin/ruby --disable-gems

require "optparse"

MAPPING = {
  image: %w(.jpg .jpeg .png .gif .bmp .tga),
}

IMGTOSIXELEXE = "C:/cloud/local/code/libs/libsixel/converters/.libs/img2sixel.exe"

def shellout(command)
  IO.popen(command) do |io|
    return io.read.strip
  end
end

def envcmdout(envkey, cmd)
  if (v = ENV[envkey]).nil? then
    v = shellout(cmd)
  end
  return v
end


#def term_height
  #return (envcmdout("LINES", ["tput", "lines"]).to_i + 500)
#end

#def term_width
  #return (envcmdout("COLUMNS", ["tput", "cols"]).to_i + 500)  
#end

class TermDim
  def initialize
    @sttysizeraw = shellout(["stty", "size"]).split(/\s/).map(&:strip).select{|s| not s.empty? }
    @sttyheight = @sttysizeraw[0].to_i
    @sttywidth = @sttysizeraw[1].to_i
    @envlines = ENV.fetch("LINES", 0).to_i
    @envcolumns = ENV.fetch("COLUMNS", 0).to_i
  end

  def width
    return (@sttywidth + @envcolumns)
  end

  def height
    return (@sttyheight + @envlines)
  end
end

module Handlers

  def self.handle_image(farg)
    dims = TermDim.new
    width = dims.width * 6
    height = dims.height * 6
    cmd = [IMGTOSIXELEXE, farg,
      "-S",
      #"-q", "low",
      "-E", "fast",
      #"-w", width, #"auto",
      #"-h", height, #"auto",
      "-l", "disable",
    ].map(&:to_s)
    #$stderr.printf("terminal dimensions: %sx%s\n", width, height)
    system(*cmd)
  end

  def self.handle_default(farg)
    system("less", "-f", farg)
  end
end


def get_type(ext)
  ext = ext.downcase
  MAPPING.each do |name, extensions|
    if extensions.include?(ext) then
      return name
    end
  end
  return :default
end

def handle(type, farg)
  case type
    when :image then
      Handlers.handle_image(farg)
    else
      #$stderr.printf("this should actually be impossible (type=%p)\n", type)
      Handlers.handle_default(farg)
  end
end

begin
  prs = OptionParser.new{|prs|
  }
  prs.parse!
  if ARGV.empty? then
    $stderr.puts("error: missing arguments")
    $stderr.puts("(reminder: 'show' displays some files on your terminal, if they're supported)")
  else
    ARGV.each do |farg|
      if File.file?(farg) then
        ext = File.extname(farg)
        type = get_type(ext)
        if type.nil? then
          $stderr.puts("No handler for #{ext.dump} files (#{farg.dump})")
        else
          handle(type, farg)
        end
      else
        $stderr.puts("No such file: #{farg.dump}")
      end
    end
  end
end
