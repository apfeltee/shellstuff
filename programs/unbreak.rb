#!/usr/bin/ruby

require "ostruct"
require "optparse"

class Unbreak
  def initialize(opts, inio, outio)
    @opts = opts
    @inio = inio
    @outio = outio
    @havemore = true
  end

  def readline
    begin
      return @inio.readline
    rescue EOFError
      @havemore = false
      return nil
    end
  end

  def unbreak_lines(sline)
    #$stderr.printf("sline = %p\n", sline)
    while true do
      nextline = readline
      if nextline == nil then
        @outio.write(currentline)
        return
      else
        @outio.write(sline[0 .. -2].rstrip + " ")
        @outio.write(nextline)
        if not nextline.rstrip.end_with?('\\') then
          return
        else
          sline = readline
        end
      end
    end
  end

  def main()
    while @havemore do
      currentline = readline
      return if (currentline == nil)
      sline = currentline.rstrip
      if sline.end_with?('\\') then
        #unbreak_lines(sline)
        nextline = readline
        if nextline == nil then
          @outio.write(currentline)
        else
          snext = nextline.rstrip
          @outio.write(sline[0 .. -2].rstrip + ' ')
          if snext.end_with?('\\') then
            @outio.write(snext[0 .. -2].rstrip + ' ')
          else
            @outio.write(nextline)
          end
        end
      else
        @outio.write(currentline)
      end
      @outio.flush
    end
  end
end

begin
  inio = $stdin
  outio = $stdout
  opts = OpenStruct.new({
  })
  OptionParser.new{|prs|
  }.parse!
  Unbreak.new(opts, inio, outio).main
end


