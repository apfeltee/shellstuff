#!/usr/bin/ruby

require "optparse"


=begin
class CRC32
  def initialize
    @hs = 0
  end

  def push(strval)
    @hs ^= Zlib::crc32(strval)
    return self
  end

  def value
    return @hs
  end

  def self.from_string(str)
    return CRC32.new.push(str).value
  end

  def self.from_file(fpath)
    cc = CRC32.new
    File.open(fpath, "rb") do |fh|
      fh.each_line do |l|
        cc.push(l)
      end
    end
    return cc.value
  end
end
=end

=begin
module FMath
  def xor(a, b)
    if defined?(Xorcist) then
      return Xorcist.xor(a, b)
    end
    return (a ^ b)
  end
end
=end

class CRC32
  # Divisor is a polynomial of degree 32 with coefficients modulo 2.
  # We store Divisor in a 33-bit Integer; the polynomial is
  #   Divisor[32] + Divisor[31] * x + ... + Divisor[0] * x**32
  Divisor = [
    0,  1,  2,  4,  5, 
    7,  8,  10, 11, 12,
    16, 22, 23, 26, 32
  ].inject(0){|sum, exponent| sum + (1 << (32 - exponent))}
 
  # This table gives the sum (without conditioning) of every possible
  # _octet_ from 0 to 255. Each _octet_ is a polynomial of degree 7,
  #   octet[7] + octet[6] * x + ... + octet[0] * x**7
  # Then remainder = Table[octet] is the remainder from
  # _octet_ times x**32 divided by Divisor,
  #   remainder[31] + remainder[30] + ... + remainder[0] * x**31
  Table = Array.new(256) do |octet|
    # Find remainder from polynomial long division.
    #    octet[ 7] * x**32 + ... +   octet[0] * x**39
    #  Divisor[32] * x**0  + ... + Divisor[0] * x**32
    remainder = octet
    (0..7).each do |i|
      # Find next term of quotient. To simplify the code,
      # we assume that Divisor[0] is 1, and we only check
      # remainder[i]. We save remainder, forget quotient.
      if remainder[i].zero?
        # Next term of quotient is 0 * x**(7 - i).
        # No change to remainder.
      else
        # Next term of quotient is 1 * x**(7 - i). Multiply
        # this term by Divisor, then subtract from remainder.
        #  * Multiplication uses left shift :<< to align
        #    the x**(39 - i) terms.
        #  * Subtraction uses bitwise exclusive-or :^.
        remainder ^= (Divisor << i)
      end
    end
    remainder >> 8      # Remove x**32 to x**39 terms.
  end

  def initialize(sum=0)
    @sum = 0
    @ispostcond = false
    _precond
  end

  def _precond
    # Pre-conditioning: Flip all 32 bits. Without this step, a string
    # preprended with extra "\0" would have same crc32 value.
    @sum ^= 0xffff_ffff
  end

  def _postcond
    # Post-conditioning: Flip all 32 bits. If we later update _crc_,
    # this step cancels the next pre-conditioning.
    @sum ^= 0xffff_ffff
  end

  def update_byte(octet)
    # Update _crc_ by continuing its polynomial long division.
    # Our current remainder is old _crc_ times x**8, plus
    # new _octet_ times x**32, which is
    #   sum[32] * x**8 + sum[31] * x**9 + ... + sum[8] * x**31 \
    #     + (sum[7] + octet[7]) * x**32 + ... \
    #     + (sum[0] + octet[0]) * x**39
    #
    # Our new _crc_ is the remainder from this polynomial divided by
    # Divisor. We split the terms into part 1 for x**8 to x**31, and
    # part 2 for x**32 to x**39, and divide each part separately.
    # Then remainder 1 is trivial, and remainder 2 is in our Table.
    remainder_1 = (@sum >> 8)
    remainder_2 = Table[(@sum & 0xff) ^ octet]
    # Our new _crc_ is sum of both remainders. (This sum never
    # overflows to x**32, so is not too big for Divisor.)
    @sum = (remainder_1 ^ remainder_2)
  end

  def update_string(str)
    if @ispostcond then
      @sum = 0
      _precond
    end
    # Iterate octets to perform polynomial long division.
    str.each_byte do |byte|
      update_byte(byte)
    end
    return self
  end

  def finish
    if not @ispostcond then
      _postcond
      @ispostcond = true
    end
  end

  def hash
    finish
    return @sum
  end

  alias_method(:value, :hash)

  def self.from_string(str)
    return CRC32.new.update_string(str).hash
  end

  def self.from_file(fpath, chunksize=(1024*32))
    cc = CRC32.new
    File.open(fpath, "rb") do |fh|
      while true do
        chunk = fh.read(chunksize)
        if chunk == nil then
          break
        end
        cc.update_string(chunk)
      end
    end
    return cc.hash
  end
end
 
#printf "0x%08x\n", CRC.crc32("The quick brown fox jumps over the lazy dog")
# => 0x414fa339


def main
  $stdout.sync = true
  (prs=OptionParser.new{|prs|
    
  }).parse!
  if ARGV.empty? then
    $stderr.puts("too few arguments")
    exit(1)
  else
    rc = 0
    ARGV.each do |f|
      begin
        val = CRC32.from_file(f)
        $stdout.printf("%d\t%s\n", val, f)
      rescue IOError => e
        rc = 1
        $stderr.printf("failed processing %p: (%s) %s\n", f, e.class.name, e.message)
      end
    end
    exit(rc)
  end
end

main