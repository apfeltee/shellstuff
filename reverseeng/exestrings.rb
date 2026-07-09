#!/usr/bin/ruby --disable=gems

## attempts to extract string-like values from PE files.
## because windows insists on using UTF-16 everywhere, it's
## actually not entirely straight-forward to extract
## text without also taking the file apart.
## hence, this file is more of a 'preview' - if it shows anything
## promising, use something else to dig deeper.
##
## also, this file is a mess.


require "stringio"

MAXLINELEN = 120

SPECIALCONV = {
  ###
  ### umlauts
  ### these get mangled much more viciously than, say, accents
  ###
  /\u{c4}/ => "Ae", # Ä
  /\u{d6}/ => "Oe", # Ö
  /\u{dc}/ => "Ue", # Ü
  /\u{e4}/ => "ae", # ä
  /\u{f6}/ => "oe", # ö
  /\u{fc}/ => "ue", # ü
  /\u{df}/ => "ss", # ß

  ###
  ### others (more to add maybe)
  ###
  /\u{20ac}/ => "EUR", # €
}

def prepare(line)
  
end


def stringify(line, maxnulls: 1)
  cprev = nil
  cnext = nil
  idx = 0
  SPECIALCONV.each do |rex, repl|
    line.gsub!(rex, repl)
  end
  ret = StringIO.new
  bytes = line.bytes
  byteslen = bytes.size
  #bytes.lazy.with_index do |byte, idx|
  while (idx < byteslen)
    byte = bytes[idx]
    if ((byte > 32) && (byte < 127)) then
      ret.write(byte.chr)
    elsif (byte == 0) then
    end
    cprev = byte
    if ((idx + 1) <= byteslen) then
      cnext = bytes[idx + 1]
    else
      cnext = nil
    end
    idx += 1
  end
  return ret.string
end

def dofile(fh, out)
  colcnt = 0
  nullcnt = 0
  begin
    fh.each_byte.with_index do |byte, idx|
      nullcnt = ((byte == 0) ? (nullcnt + 1) : 0)
      ch = byte.chr
      if ((byte >= 32) && (byte < 127)) || (ch.ascii_only? && (byte != 0)) then
        $stdout.write(ch)
        colcnt += 1
      else
        #$stdout.write(".")
        #colcnt += 1
      end
      if (colcnt >= MAXLINELEN) then
        #$stderr.puts("*** colcnt=#{colcnt}***")
        #$stdout.write("\n")
        colcnt = 0
      end
    end
  rescue Interrupt => e
    # non-error, ignore
  ensure
    $stdout.write("\n")
  end
end

begin
  $stdout.sync = true
  selfname = File.basename($0)
  if ARGV.empty? && $stdin.tty? then
    $stderr.printf("usage: %s [<file> ...] (or stdin)\n", selfname)
  elsif not $stdin.tty? then
    dofile($stdin, $stdout)
  else
    ARGV.each do |file|
      File.open(file, "rb:UTF-8") do |fh|
        #$stderr.printf("** stringifying %p ...\n", file)
        dofile(fh, $stdout)
      end
    end
  end
end
