require 'epitools/minimal'
require 'epitools/core_ext/numbers'

class String
  
  #
  # Could this string be cast to an integer?
  #
  def integer?
    strip.match(/^\d+$/) ? true : false
  end

  #
  # 'true' if the string's length is 0 (after whitespace has been stripped from the ends)
  #
  def blank?
    strip.size == 0
  end

  #
  # Does this string contain something that means roughly "true"?
  #
  def truthy?
    case strip.downcase
    when "1", "true", "yes", "on", "enabled", "affirmative"
      true
    else
      false
    end
  end

  #
  # Convert \r\n to \n
  #
  def to_unix
    gsub("\r\n", "\n")
  end
  
  #
  # Remove redundant whitespaces (not including newlines).
  #
  def tighten
    gsub(/[\t ]+/,' ').strip
  end

  #
  # Remove redundant whitespace AND newlines.
  #
  def dewhitespace
    gsub(/\s+/,' ').strip
  end

  #
  # Remove ANSI color codes.
  #
  def strip_color
    gsub(/\e\[.*?(\d)+m/, '')
  end
  alias_method :strip_ansi, :strip_color 

  #
  # Like #lines, but skips empty lines and removes \n's.
  #
  def nice_lines
    # note: $/ is the platform's newline separator
    split($/).select{|l| not l.blank? }
  end
  
  alias_method :nicelines,   :nice_lines
  alias_method :clean_lines, :nice_lines


  #
  # Iterate over slices of the string of size `slice_width`.
  #
  def each_slice(slice_width, &block)
    max = size
    p = 0
    while p < max
      yield self[p...p+slice_width]
      p += slice_width
    end
  end
  enumerable :each_slice

  #
  # The Infamous Caesar-Cipher. Unbreakable to this day.
  #
  def rot13
    tr('n-za-mN-ZA-M', 'a-zA-Z')
  end
  
  #
  # Convert non-URI characters into %XXes.
  #
  def urlencode
    URI.escape(self)
  end
  
  #
  # Convert an URI's %XXes into regular characters.
  #
  def urldecode
    URI.unescape(self)
  end

  #
  # Convert a query string to a hash of params
  #
  def to_params
    require 'cgi' unless defined? CGI.parse
    CGI.parse(self).map_values do |v|
      # CGI.parse wraps every value in an array. Unwrap them!
      if v.is_a?(Array) and v.size == 1
        v.first
      else
        v 
      end
    end      
  end
  

  #
  # Cached constants for base62 decoding.
  #  
  BASE62_DIGITS  = Hash[ Integer::BASE62_DIGITS.zip((0...Integer::BASE62_DIGITS.size).to_a) ]
  BASE62_BASE    = Integer::BASE62_BASE
  
  #
  # Convert a string (encoded in base16 "hex" -- for example, an MD5 or SHA1 hash)
  # into "base62" format. (See Integer#to_base62 for more info.)  
  #
  def to_base62
    to_i(16).to_base62
  end
  
  #
  # Convert a string encoded in base62 into an integer.
  # (See Integer#to_base62 for more info.)
  #
  def from_base62
    accumulator = 0
    digits = chars.map { |c| BASE62_DIGITS[c] }.reverse
    digits.each_with_index do |digit, power|
      accumulator += (BASE62_BASE**power) * digit if digit > 0
    end
    accumulator
  end

  #
  # Decode a mime64/base64 encoded string
  #
  def from_base64
    Base64.decode64 self
  end
  alias_method :decode64, :from_base64 
  
  #
  # Encode into a mime64/base64 string
  #
  def to_base64
    Base64.encode64 self
  end
  alias_method :base64,   :to_base64
  alias_method :encode64, :to_base64

  #
  # MD5 the string
  #  
  def md5
    Digest::MD5.hexdigest self
  end
  
  #
  # SHA1 the string
  #  
  def sha1
    Digest::SHA1.hexdigest self
  end
  
  #
  # gzip the string
  #
  def gzip(level=nil)
    zipped = StringIO.new
    Zlib::GzipWriter.wrap(zipped, level) { |io| io.write(self) }
    zipped.string
  end
  
  #
  # gunzip the string
  #
  def gunzip
    data = StringIO.new(self)
    Zlib::GzipReader.new(data).read
  end
  
  #
  # deflate the string
  #
  def deflate(level=nil)
    Zlib::Deflate.deflate(self, level)
  end
  
  #
  # inflate the string
  #
  def inflate
    Zlib::Inflate.inflate(self)
  end
  
  # `true` if this string starts with the substring 
  #  
  def startswith(substring)
    self[0...substring.size] == substring
  end
  
  #
  # `true` if this string ends with the substring 
  #  
  def endswith(substring)
    self[-substring.size..-1] == substring
  end

  #
  # Parse this string as JSON
  #
  def from_json
    JSON.parse(self)
  end
  
  #
  # Parse this string as YAML
  #
  def from_yaml
    YAML.load(self)
  end

  #
  # Unmarshal the string (transform it into Ruby datatypes).
  #  
  def unmarshal
    Marshal.restore self
  end
  alias_method :from_marshal, :unmarshal

  #
  # Convert the string to a Path object.
  #
  def as_path
    Path[self]
  end
  alias_method :to_p, :as_path
  
  #
  # Convert this string into a string describing this many of the string.
  # (Note: Doesn't know anything about proper grammar.)
  #
  # Example:
  #   "cookie".amount(0)    #=> "0 cookies"
  #   "shirt".amount(17)    #=> "17 shirts"
  #   "dollar".amount(-10)  #=> "-10 dollars"
  #   "love".amount(1)      #=> "1 love"
  #
  def amount(n)
    case n
    when 0 
      "0 #{self}s"
    when 1, -1
      "#{n} #{self}"
    else
      "#{n} #{self}s"
    end
  end
  
  #
  # Converts time duration strings (mm:ss, hh:mm:ss, or dd:hh:mm:ss) to seconds.
  # (The reverse of Integer#to_hms)
  #
  def from_hms
    nums = split(':').map(&:to_i)
    nums_and_units = nums.reverse.zip %w[seconds minutes hours days]
    nums_and_units.map { |num, units| num.send(units) }.sum
  end
  
  unless public_method_defined? :to_proc
  
    #  
    # String#to_proc
    #
    # See http://weblog.raganwald.com/2007/10/stringtoproc.html
    #
    # Ported from the String Lambdas in Oliver Steele's Functional Javascript
    # http://osteele.com/sources/javascript/functional/
    #
    # This work is licensed under the MIT License:
    #
    # (c) 2007 Reginald Braithwaite
    # Portions Copyright (c) 2006 Oliver Steele
    # 
    # Permission is hereby granted, free of charge, to any person obtaining
    # a copy of this software and associated documentation files (the
    # "Software"), to deal in the Software without restriction, including
    # without limitation the rights to use, copy, modify, merge, publish,
    # distribute, sublicense, and/or sell copies of the Software, and to
    # permit persons to whom the Software is furnished to do so, subject to
    # the following conditions:
    # 
    # The above copyright notice and this permission notice shall be
    # included in all copies or substantial portions of the Software.
    # 
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    #
    def to_proc &block
      params = []
      expr = self
      sections = expr.split(/\s*->\s*/m)
      if sections.length > 1 then
          eval_block(sections.reverse!.inject { |e, p| "(Proc.new { |#{p.split(/\s/).join(', ')}| #{e} })" }, block)
      elsif expr.match(/\b_\b/)
          eval_block("Proc.new { |_| #{expr} }", block)
      else
          leftSection = expr.match(/^\s*(?:[+*\/%&|\^\.=<>\[]|!=)/m)
          rightSection = expr.match(/[+\-*\/%&|\^\.=<>!]\s*$/m)
          if leftSection || rightSection then
              if (leftSection) then
                  params.push('$left')
                  expr = '$left' + expr
              end
              if (rightSection) then
                  params.push('$right')
                  expr = expr + '$right'
              end
          else
              self.gsub(
                  /(?:\b[A-Z]|\.[a-zA-Z_$])[a-zA-Z_$\d]*|[a-zA-Z_$][a-zA-Z_$\d]*:|self|arguments|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/, ''
              ).scan(
                /([a-z_$][a-z_$\d]*)/i
              ) do |v|  
                params.push(v) unless params.include?(v)
              end
          end
          eval_block("Proc.new { |#{params.join(', ')}| #{expr} }", block)
      end
    end
    
    private
    
    def eval_block(code, block)
      eval code, block && block.binding
    end
    
  end # unless public_method_defined? :to_proc
  
end


