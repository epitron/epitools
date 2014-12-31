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
  # Is there anything in the string? (ignoring whitespace/newlines)
  #
  def any?
    not blank?
  end
  alias_method :present?, :any?

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
  # Convert string to "Title Case" (first letter of each word capitalized)
  #
  def titlecase!
    downcase!
    gsub!(/\b\w/) { |m| m.upcase }
  end

  #
  # Return a new string converted to "Title Case" (first letter of each word capitalized)
  #
  def titlecase
    dup.titlecase!
  end


  #
  # A Regexp to recognize ANSI escape sequences
  #
  COLOR_REGEXP = /\e\[.*?(\d)+m/

  #
  # This string contains ANSI (VT100) control codes
  #
  def contains_color?
    self[ANSI_REGEXP]
  end  
  alias_method :contains_colors?, :contains_color?
  alias_method :contains_ansi?,  :contains_color?

  #
  # Remove ANSI color codes.
  #
  def strip_color
    gsub(ANSI_REGEXP, '')
  end
  alias_method :strip_ansi, :strip_color 

  #
  # Like #each_line, but skips empty lines and removes \n's.
  #
  def nice_lines
    # note: $/ is the platform's newline separator
    split($/).select{|l| not l.blank? }
  end
  
  alias_method :nicelines,   :nice_lines
  alias_method :clean_lines, :nice_lines

  #
  # Like #each_line, but removes trailing \n
  #
  def each_chomped
    each_line { |line| yield line.chomp }
  end
  alias_method :chomped_lines, :each_chomped
  alias_method :chomp_lines,   :each_chomped


  #
  # Indent all the lines, if "prefix" is a string, prepend that string
  # to each lien. If it's an integer, prepend that many spaces.
  #
  def indent(prefix="  ")
    prefix = (" " * prefix) if prefix.is_an? Integer

    if block_given?
      lines.each { |line| yield prefix + line }
    else
      lines.map { |line| prefix + line }.join('')
    end
  end

  #
  # Use Nokogiri to parse this string as HTML, and return an indented version
  #
  def nice_html(indent=2)
    Nokogiri::HTML.fragment(self).to_xhtml(indent: indent)
  end
  alias_method :nicehtml,    :nice_html
  alias_method :indent_html, :nice_html

  #
  # Wrap the lines in the string so they're at most "width" wide.
  # (If no width is specified, defaults to the width of the terminal.)
  #
  def wrap(width=nil)
    if width.nil? or width < 0
      require 'io/console'
      _, winwidth = STDIN.winsize

      if width < 0
        width = (winwidth + width) - 1
      else
        width = winwidth - 1
      end
    end

    return self if size <= width

    strings   = []
    start_pos = 0
    end_pos   = width

    loop do
      split_pos = rindex(/\s/, end_pos) || end_pos

      strings << self[start_pos...split_pos]

      start_pos = index(/\S/, split_pos)
      break if start_pos == nil
      end_pos   = start_pos + width

      if end_pos > size
        strings << self[start_pos..-1]
        break
      end
    end

    if block_given?
      strings.each { |s| yield s }
    else
      strings.join("\n")
    end
  end

  #
  # Wrap all lines at window size, and indent 
  #
  def wrapdent(prefix, width=nil)
    if width
      width = width - prefix.size
    else
      width = -prefix.size
    end

    wrap(width).each_line.map { |line| prefix + line }.join
  end

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
    params = {}

    split(/[&;]/).each do |pairs|
      key, value = pairs.split('=',2).collect { |v| CGI.unescape(v) }

      if key and value
        params[key] ||= []
        params[key] << value
      end
    end

    params.map_values { |v| v.size > 1 ? v : v.first }
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
    unpack("m").first
  end
  alias_method :decode64, :from_base64 
  
  #
  # Encode into a mime64/base64 string
  #
  def to_base64
    [self].pack("m")
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
  def startswith?(substring)
    self[0...substring.size] == substring
  end
  alias_method :startswith, :startswith?
  
  #
  # `true` if this string ends with the substring 
  #  
  def endswith?(substring)
    self[-substring.size..-1] == substring
  end
  alias_method :endswith, :endswith?

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
  # Converts time duration strings (mm:ss, mm:ss.dd, hh:mm:ss, or dd:hh:mm:ss) to seconds.
  # (The reverse of Integer#to_hms)
  #
  def from_hms
    nums = split(':')

    nums[-1] = nums[-1].to_f if nums[-1] =~ /\d+\.\d+/ # convert fractional seconds to a float
    nums.map! { |n| n.is_a?(String) ? n.to_i : n } # convert the rest to integers

    nums_and_units = nums.reverse.zip %w[seconds minutes hours days]
    nums_and_units.map { |num, units| num.send(units) }.sum
  end
  
  #
  # Print a hexdump of the string to STDOUT (coloured, if the terminal supports it)
  #
  def hexdump
    Hex.dump(self)
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


