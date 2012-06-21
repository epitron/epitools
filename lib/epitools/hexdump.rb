require 'epitools'

ASCII_PRINTABLE = (33..126)

=begin
000352c0  ed 33 8c 85 6e cc f6 f7  72 79 1c e3 3a b4 c2 c6  |.3..n...ry..:...|
000352d0  c8 8d d6 ee 3e 68 a1 a5  ae b2 b7 97 a4 1d 5f a7  |....>h........_.|
000352e0  d8 7d 28 db f6 8a e7 8a  7b 8d 0b bd 35 7d 25 3c  |.}(.....{...5}%<|
000352f0  8b 3c c8 9d ec 04 85 54  92 a0 f7 a8 ed cf 05 7d  |.<.....T.......}|
00035300  b5 e3 9e 35 f0 79 9f 51  74 e3 60 ee 0f 03 8e 3f  |...5.y.Qt.`....?|
00035310  05 5b 91 87 e6 48 48 ee  a3 77 ae ad 5e 2a 56 a2  |.[...HH..w..^*V.|
00035320  b6 96 86 f3 3c 92 b3 c8  62 4a 6f 96 10 5c 9c bb  |....<...bJo..\..|
=end

# whoops!
# 48:  d2 b1 6d 31 3e 67 e1 88  99 8b 4b 34 1d 61 05 15  |..m1g....K4.a..|
#


module Hex

  DUMP_COLORS = Rash.new(
    /\d/ => 13,
    /\w/ => 3,
    nil => 9,
    :default => 7
  )

  def self.dump(data, options={})
    base_offset   = options[:base_offset] || 0
    color         = options[:color].nil? ? true : options[:color]
    highlight     = options[:highlight]

    p options
    p color

    lines               = data.scan(/.{1,16}/m)
    max_offset          = (base_offset + data.size) / 16 * 16
    max_offset_width    = max_offset.to_s.size
    max_hex_width       = 3 * 16 + 1

    p [max_offset, max_offset_width]
    lines.each_with_index do |line,n|
      offset    = base_offset + n*16
      bytes     = line.unpack("C*")
      hex       = bytes.map { |c| "%0.2x" % c }.insert(8, '').join(' ')

      plain = bytes.map do |c|
        if ASCII_PRINTABLE.include?(c)
          c = c.chr
        else
          color ? '<9>.</9>' : '.'
        end
      end.join('')

      puts "<11>#{offset.to_s.ljust(max_offset_width)}<3>:  <14>#{hex.ljust(max_hex_width)} <8>|<15>#{plain}<8>|".colorize
    end
  end

end

def hexdump(*args)
  Hex.dump(*args)
end

if $0 == __FILE__
  data = (0..64).map{ rand(255).chr }.join('')
  Hex.dump(data)
  puts
  Hex.dump(data, :color=>false)
  puts

  data = "1234567890"*10
  Hex.dump(data)
end
