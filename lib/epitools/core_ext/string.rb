require 'epitools/minimal'
require 'epitools/core_ext/truthiness'
require 'epitools/core_ext/numbers'

class String

  #
  # For `titlecase`
  #
  LOWERCASE_WORDS = Set.new %w[of to or the and an a at is for from in]

  #
  # For `words_without_stopwords`
  #
  STOP_WORDS = %w[a cannot into our thus about co is ours to above could it ourselves together across down its out too after during itself over toward afterwards each last own towards again eg latter per under against either latterly perhaps until all else least rather up almost elsewhere less same upon alone enough ltd seem us along etc many seemed very already even may seeming via also ever me seems was although every meanwhile several we always everyone might she well among everything more should were amongst everywhere moreover since what an except most so whatever and few mostly some when another first much somehow whence any for must someone whenever anyhow former my something where anyone formerly myself sometime whereafter anything from namely sometimes whereas anywhere further neither somewhere whereby are had never still wherein around has nevertheless such whereupon as have next than wherever at he no that whether be hence nobody the whither became her none their which because here noone them while become hereafter nor themselves who becomes hereby not then whoever becoming herein nothing thence whole been hereupon now there whom before hers nowhere thereafter whose beforehand herself of thereby why behind him off therefore will being himself often therein with below his on thereupon within beside how once these without besides however one they would between i only this yet beyond ie onto those you both if or though your but in other through yours by inc others throughout yourself can indeed otherwise thru yourselves]

  #
  # Convert \r\n to \n
  #
  def to_unix
    gsub("\r\n", "\n")
  end

  #
  # Escape shell characters (globs, quotes, parens, etc.)
  #
  def shellescape
    Shellwords.escape(self)
  end

  #
  # Remove redundant whitespaces (not including newlines).
  #
  def tighten
    gsub(/[\t ]+/,' ').strip
  end

  #
  # Smash together all the characters in a string (removing whitespace)
  #
  def smash
    downcase.scan(/\w+/).join
  end

  #
  # Remove redundant whitespace AND newlines.
  #
  def dewhitespace
    gsub(/\s+/,' ').strip
  end

  #
  # Return a new string converted to "Title Case" (first letter of each word capitalized)
  #
  def titlecase
    first = true
    words = downcase.split(/(?<!\w')\b/)

    words.map.with_index do |word,i|
      if LOWERCASE_WORDS.include?(word) and i > 0 # leave LOWERCASE_WORDS lowercase, unless it's the first word.
        word
      else
        word.gsub(/^\w/) { |c| c.upcase } # capitalize first letter
      end
    end.join('')
  end

  #
  # Convert string to "Title Case" (first letter of each word capitalized)
  #
  def titlecase!
    replace(titlecase)
  end

  #
  # A Regexp to recognize ANSI escape sequences
  #
  COLOR_REGEXP = /\e\[.*?(\d)*[mA-Z]/

  #
  # This string contains ANSI (VT100) control codes
  #
  def contains_color?
    self[COLOR_REGEXP]
  end
  alias_method :contains_colors?, :contains_color?
  alias_method :contains_ansi?,  :contains_color?

  #
  # Remove ANSI color codes.
  #
  def strip_color
    gsub(COLOR_REGEXP, '')
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


  def split_at(boundary, **options)
    include_boundary = options[:include_boundary] || false

    boundary = Regexp.new(Regexp.escape(boundary)) if boundary.is_a?(String)
    s        = StringScanner.new(self)

    Enumerator.new do |yielder|
      loop do
        if match = s.scan_until(boundary)
          if include_boundary
            yielder << match
          else
            yielder << match[0..-(s.matched_size+1)]
          end
        else
          yielder << s.rest if s.rest?
          break
        end
      end
    end
  end

  def split_after(boundary)
    split_at(boundary, include_boundary: true)
  end

  def split_before(boundary)
    raise "Why would you want this? Sorry, unimplemented. Send patches."
  end

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
  # Word-wrap the string so each line is at most `width` wide.
  # Returns a string, or, if a block is given, yields each
  # word-wrapped line to the block.
  #
  # If `width` is nil, find the current width of the terminal and use that.
  # If `width` is negative, subtract `width` from the terminal's current width.
  #
  def wrap(width=nil)
    if width.nil? or width < 0
      term_width, _ = Term.size

      if width and width < 0
        width = (term_width - 1) + width
      else
        width = term_width - 1
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

  alias_method :word_wrap, :wrap


  #
  # Wrap all lines at window size, and indent
  #
  def wrap_and_indent(prefix, width=nil)
    prefix = " "*prefix if prefix.is_a? Numeric

    prefix_size = prefix.strip_color.size

    if width
      width = width - prefix_size
    else
      width = -prefix_size
    end

    wrap(width).each_line.map { |line| prefix + line }.join
  end
  alias_method :wrapdent, :wrap_and_indent

  def sentences
    split_after(/[\.\!\?]+/).lazy.map {|s| s.strip.gsub(/\s+/, " ") }
  end

  def words
    scan /[[:alnum:]]+/
  end

  def words_without_stopwords
    downcase.words - STOP_WORDS
  end
  alias_method :without_stopwords, :words_without_stopwords

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
  # URI.parse the string and return an URI object
  #
  def to_uri
    URI.parse self
  end
  alias_method :to_URI, :to_uri

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
  # Raw bytes to an integer (as big as necessary)
  #
  def to_i_from_bytes(big_endian=false)
    bs = big_endian ? bytes.reverse_each : bytes.each
    bs.with_index.inject(0) { |sum,(b,i)| (b << (8*i)) + sum }
  end

  #
  # Cached constants for base conversion.
  #
  BASE_DIGITS = Integer::BASE_DIGITS.map.with_index.to_h

  #
  # Convert a string encoded in some base <= 64 into an integer.
  # (See Integer#to_base for more info.)
  #
  def from_base(base=10)
    n = 0
    chars.reverse_each.with_index do |c, power|
      value = BASE_DIGITS[c]
      n += (base**power) * value
    end
    n
  end

  def from_base62
    from_base(62)
  end

  #
  # Convert a string (encoded in base16 "hex" -- for example, an MD5 or SHA1 hash)
  # into "base62" format. (See Integer#to_base62 for more info.)
  #
  def to_base62
    to_i(16).to_base62
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
  # Convert Python serialized bencoded (pickled) objects to Ruby Objects
  #
  def from_bencode
    BEncode.load(self)
  end
   
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
  # SHA256 the string
  #
  def sha256
    Digest::SHA256.hexdigest self
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
    # See: http://weblog.raganwald.com/2007/10/stringtoproc.html
    #
    # Ported from the String Lambdas in Oliver Steele's Functional Javascript
    # http://osteele.com/sources/javascript/functional/
    #
    # This work is licensed under the MIT License:
    #
    # (c) 2007 Reginald Braithwaite
    # Portions Copyright (c) 2006 Oliver Steele
    #
    #
    # ## Basic Usage
    #
    # 'x+1'.to_proc[2];
    #      → 3
    # 'x+2*y'.to_proc[2, 3];
    #      → 8
    # or (more usefully) later:
    #
    # square = 'x*x'.to_proc;
    # square(3);
    #      → 9
    # square(4);
    #      → 16
    #
    # ## Explicit parameters
    #
    # If the string contains a ->, this separates the parameters from the body.
    #
    # 'x y -> x+2*y'.to_proc[2, 3];
    #      → 8
    # 'y x -> x+2*y'.to_proc[2, 3];
    #      → 7
    # Otherwise, if the string contains a _, it’s a unary function and _ is name of the parameter:
    #
    # '_+1'.to_proc[2];
    #      → 3
    # '_*_'.to_proc[3];
    #      → 9
    # ## Implicit parameters
    #
    # If the string doesn’t specify explicit parameters, they are implicit.
    #
    # If the string starts with an operator or relation besides -, or ends with an operator or relation, then its implicit arguments are placed at the beginning and/or end:
    #
    # '*2'.to_proc[2];
    #      → 4
    # '/2'.to_proc[4];
    #      → 2
    # '2/'.to_proc[4];
    #      → 0.5
    # '/'.to_proc[2, 4];
    #      → 0.5
    # ’.’ counts as a right operator:
    #
    # '.abs'.to_proc[-1];
    #  → 1
    #
    #
    # Otherwise, the variables in the string, in order of occurrence, are its parameters.
    #
    # 'x+1'.to_proc[2];
    #      → 3
    # 'x*x'.to_proc[3];
    #      → 9
    # 'x + 2*y'.to_proc[1, 2];
    #      → 5
    # 'y + 2*x'.to_proc[1, 2];
    #      → 5
    #
    # ## Chaining
    #
    # Chain -> to create curried functions.
    #
    # 'x y -> x+y'.to_proc[2, 3];
    #      → 5
    # 'x -> y -> x+y'.to_proc[2][3];
    #      → 5
    # plus_two = 'x -> y -> x+y'.to_proc[2];
    # plus_two[3]
    #      → 5
    #
    # Using String#to_proc in Idiomatic Ruby
    #
    # Ruby on Rails popularized Symbol#to_proc, so much so that it will be part of Ruby 1.9.
    #
    # If you like:
    #
    # %w[dsf fgdg fg].map(&:capitalize)
    #     → ["Dsf", "Fgdg", "Fg"]
    # then %w[dsf fgdg fg].map(&'.capitalize') isn’t much of an improvement.
    #
    # But what about doubling every value in a list:
    #
    # (1..5).map &'*2'
    #     → [2, 4, 6, 8, 10]
    #
    # Or folding a list:
    #
    # (1..5).inject &'+'
    #     → 15
    #
    # Or having fun with factorial:
    #
    # factorial = "(1.._).inject &'*'".to_proc
    # factorial[5]
    #     → 120
    #
    # LICENSE:
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
