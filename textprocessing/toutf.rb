#!/usr/bin/ruby

def conv_utf_guts(inpstr, outstr, rubyesque, cc)

  highsurrogate = 0
  pad = 0
  n = 0
  bchar = "\x5C"


  if (cc < 0 || cc > 0xFFFF)
    $stderr.printf("!Error: unexpected code result, cc=%p!\n", cc)
  end
  if (highsurrogate != 0) then
    # this is a supp char, and cc contains the low surrogate
    if (0xDC00 <= cc && cc <= 0xDFFF) then
      suppcp = 0x10000 + ((highsurrogate - 0xD800) << 10) + (cc - 0xDC00)
      #pad = suppcp.to_s(16).upcase
      pad = sprintf("%02X", suppcp)
      outstr.write(bchar)
      outstr.write("u{")
      outstr.write(pad)
      outstr.write("}")
      highsurrogate = 0
      return
    else
      $stderr.printf("!Error: low surrogate expected, cc=%p!\n", cc)
      highsurrogate = 0
    end
  end
  # start of supplementary character
  if (0xD800 <= cc && cc <= 0xDBFF) then
    highsurrogate = cc
  else
    # this is a BMP character
    # outstr.write(dec2hex(cc) + ' ')
    if (cc == 0) then
      outstr.write(bchar)
      outstr.write("0")
    elsif (cc == 8) then
      outstr.write(bchar)
      outstr.write("b")
    elsif (cc == 9) then
      outstr.write(bchar)
      outstr.write("t")
    elsif (cc == 10) then
      outstr.write(bchar)
      outstr.write("n")
    elsif (cc == 13) then
      outstr.write(bchar)
      outstr.write("r")
    elsif (cc == 11) then
      outstr.write(bchar)
      outstr.write("v")
    elsif (cc == 12) then
      outstr.write(bchar)
      outstr.write("f")
    elsif (cc == 34) then
      # '"' (double quote)
      #outstr.write(34.chr)
      outstr.write(bchar)
      outstr.write("x22")
    elsif (cc == 39) then
      # '\'' (single quote)
      #outstr.write(39.chr)
      outstr.write(bchar)
      outstr.write("x27")
    elsif (cc == 92) then
      # '\\' (single backward slash)
      #outstr.write(92.chr)
      outstr.write(bchar)
      outstr.write("x5C")
    else
      if (cc > 0x00 && cc < 0x20) then
        outstr.write(bchar)
        outstr.write("x")
        #outstr.write(cc.to_s(16).upcase)
        outstr.write(sprintf("%02X", cc))
      elsif (cc > 0x7E && cc < 0xA0) then
        outstr.write(bchar)
        outstr.write("x")
        #outstr.write(cc.to_s(16).upcase)
        outstr.write(sprintf("%02X", cc))
      elsif (cc > 0x1f && cc < 0x7F) then
        # this is because ruby's implicit handling of #... stuff in strings. :(
        if cc == 32 then
          outstr.write(bchar)
          outstr.write("x20")
        elsif cc == 35 then
          outstr.write(bchar)
          outstr.write("x23")
        else
          outstr.write(cc.chr)
        end
      else
        #pad = cc.to_s(16).upcase
        pad = sprintf("%04X", cc)
        #while pad.length < 4 do
        #  pad = '0' + pad
        #end
        if false && rubyesque then
          outstr.write(bchar)
          outstr.write("u")
          outstr.write(pad)
        else
          outstr.write(bchar)
          outstr.write("u{")
          outstr.write(pad)
          outstr.write("}")
        end
      end
    end
  end

end

def conv_toutftext(inpstr, outstr, rubyesque)
  ###
  ### WARNING:
  ### each_char iterates over each rune, *not* bytes!
  ###
  inpstr.each_char do |rawch|
    begin
      cc = rawch.ord
      conv_utf_guts(inpstr, outstr, rubyesque, cc)
    rescue => ex
      $stderr.printf("failed to get ord of %p: (%s) %s\n", rawch, ex.class.name, ex.message)
      #rawch.codepoints.each do |cc|
      rawch.bytes.each do |cc|
        conv_utf_guts(inpstr, outstr, rubyesque, cc)
      end
    end
  end
end

begin
  conv_toutftext($stdin, $stdout, true)
end
