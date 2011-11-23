require 'epitools'

## Alias "Enumerator" to "Enum"

if RUBY_VERSION["1.8"]
  require 'enumerator' 
  Enumerator = Enumerable::Enumerator unless defined? Enumerator
end

unless defined? Enum
  if defined? Enumerator
    Enum = Enumerator 
  else
    $stderr.puts "WARNING: Couldn't find the Enumerator class. Enum will not be available."
  end
end

RbConfig = Config unless defined? RbConfig

class Object
  
  #
  # Slightly gross hack to add a class method.
  #
  def self.alias_class_method(dest, src)
    metaclass.send(:alias_method, dest, src)
  end
  
  #
  # Default "integer?" behaviour.
  #
  def integer?; false; end
   
  #
  # `truthy?` means `not blank?`
  #
  def truthy?
    if respond_to? :blank?
      not blank?
    else
      not nil?
    end
  end
  
  def marshal
    Marshal.dump self
  end

  #
  # Lets you say: `object.is_an? Array`
  #  
  alias_method :is_an?, :is_a?

end

class TrueClass
  def truthy?; true; end
end

class FalseClass
  def truthy?; false; end
end

class Float
  #
  # 'true' if the float is 0.0
  #
  def blank?; self == 0.0; end
end

class NilClass
  #
  # Always 'true'; nil is considered blank.
  #
  def blank?; true; end
end

class Symbol
  #
  # Symbols are never blank.
  #
  def blank?; false; end
end



class Numeric

  def integer?; true; end

  def truthy?; self > 0; end

  def commatize  
    to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
  end

  #
  # Time methods
  #
  {
  
    'second'  => 1,
    'minute'  => 60,
    'hour'    => 60 * 60,
    'day'     => 60 * 60 * 24,
    'week'    => 60 * 60 * 24 * 7,
    'month'   => 60 * 60 * 24 * 30,
    'year'    => 60 * 60 * 24 * 364.25,
    
  }.each do |unit, scale|
    define_method(unit)     { self * scale }
    define_method(unit+'s') { self * scale }
  end
  
  def ago
    Time.now - self
  end
  
  def from_now
    Time.now + self
  end
  
end

class Integer
  
  #
  # 'true' if the integer is 0
  #
  def blank?; self == 0; end

  #
  # Convert the number into a hexadecimal string representation.
  # (Identical to to_s(16), except that numbers < 16 will have a 0 in front of them.)
  #
  def to_hex
    "%0.2x" % self
  end
    
  #
  # Convert the number to an array of bits (least significant digit first, or little-endian).
  #
  def to_bits
    # TODO: Why does thos go into an infinite loop in 1.8.7?
    ("%b" % self).chars.to_a.reverse.map(&:to_i)
  end
  alias_method :bits, :to_bits
  
  #
  # Cached constants for base62 encoding
  #
  BASE62_DIGITS   = ['0'..'9', 'A'..'Z', 'a'..'z'].map(&:to_a).flatten 
  BASE62_BASE     = BASE62_DIGITS.size

  #
  # Convert a number to a string representation (in "base62" encoding).
  # 
  # Base62 encoding represents the number using the characters: 0..9, A..Z, a..z
  #
  # It's the same scheme that url shorteners and YouTube uses for their
  # ID strings. (eg: http://www.youtube.com/watch?v=dQw4w9WgXcQ)
  #
  def to_base62
    result = []
    remainder = self
    max_power = ( Math.log(self) / Math.log(BASE62_BASE) ).floor
    
    max_power.downto(0) do |power|
      divisor = BASE62_BASE**power
      #p [:div, divisor, :rem, remainder]      
      digit, remainder = remainder.divmod(divisor)
      result << digit
    end
    
    result << remainder if remainder > 0
    
    result.map{|digit| BASE62_DIGITS[digit]}.join ''
  end

  #
  # Returns the all the prime factors of a number.
  #
  def factors
    Prime # autoload the prime module
    prime_division.map { |n,count| [n]*count }.flatten 
  end
  
end


#
# Monkeypatch [] into Bignum and Fixnum using class_eval.
#
# (This is necessary because [] is defined directly on the classes, and a mixin
#  module will still be overridden by Big/Fixnum's native [] method.)
#
[Bignum, Fixnum].each do |klass|
  
  klass.class_eval do
    
    alias_method :bit, :"[]"
    
    #
    # Extends [] so that Integers can be sliced as if they were arrays.
    #
    def [](arg)
      case arg
      when Integer
        self.bit(arg)
      when Range
        self.bits[arg]
      end
    end
    
  end
  
end


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
  # Parse object as JSON
  #
  def from_json
    JSON.parse self
  end
  
  #
  # Convert the string to a Path object.
  #
  def as_path
    Path[self]
  end
  alias_method :to_p, :as_path
  
  def unmarshal
    Marshal.restore self
  end
  
end


class Array

  #
  # flatten.compact.uniq
  #
  def squash
    flatten.compact.uniq
  end
  
  #
  # Removes the elements from the array for which the block evaluates to true. 
  # In addition, return the removed elements.
  #
  # For example, if you wanted to split an array into evens and odds:
  #
  #   nums = [1,2,3,4,5,6,7,8,9,10,11,12]
  #   even = nums.remove_if { |n| n.even? }   # remove all even numbers from the "nums" array and return them
  #   odd = nums                              # "nums" now only contains odd numbers
  #
  def remove_if(&block)
    removed = []
    
    delete_if do |x|
      if block.call(x)
        removed << x
        true
      else
        false
      end
    end
    
    removed
  end
  
  #
  # zip from the right (or reversed zip.)
  #
  # eg:
  #   >> [5,39].rzip([:hours, :mins, :secs]) 
  #   => [ [:mins, 5], [:secs, 39] ]
  #
  def rzip(other)
    # That's a lotta reverses!
    reverse.zip(other.reverse).reverse
  end  
  
  #
  # Pick the middle element.
  #
  def middle
    self[(size-1) / 2]
  end
  
  #
  # XOR operator
  #
  def ^(other)
    (self | other) - (self & other)
  end
  
  #
  # Pick a random element.
  #
  def pick
    self[rand(size)]
  end
  
  #
  # Divide the array into n pieces.
  #
  def / pieces 
    piece_size = (size.to_f / pieces).ceil
    each_slice(piece_size).to_a
  end
  

  alias_method :unzip, :transpose

end


module Enumerable

  #
  # 'true' if the Enumerable has no elements
  #
  def blank?
    not any?
  end

  #
  # I enjoy typing ".all" more than ".to_a"
  #
  alias_method :all, :to_a
  
  #
  # Split this enumerable into chunks, given some boundary condition. (Returns an array of arrays.)
  #
  # Options:
  #   :include_boundary => true  #=> include the element that you're splitting at in the results  
  #                                  (default: false)
  #   :after => true             #=> split after the matched element (only has an effect when used with :include_boundary)  
  #                                  (default: false)
  #   :once => flase             #=> only perform one split (default: false)
  #
  # Examples: 
  #   [1,2,3,4,5].split{ |e| e == 3 }                           
  #   #=> [ [1,2], [4,5] ]
  #
  #   [1,2,3,4,5].split(:include_boundary=>true) { |e| e == 3 } 
  #   #=> [ [1,2], [3,4,5] ] 
  #
  #   chapters = File.read("ebook.txt").split(/Chapter \d+/, :include_boundary=>true)
  #   #=> [ ["Chapter 1", ...], ["Chapter 2", ...], etc. ]
  #
  def split_at(matcher=nil, options={}, &block)
    # TODO: Ruby 1.9 returns Enumerators for everything now. Maybe use that?
    
    return self unless self.any?
    
    include_boundary = options[:include_boundary] || false

    if matcher.nil?
      boundary_test_proc = block
    else
      if matcher.is_a? String or matcher.is_a? Regexp
        boundary_test_proc = proc { |element| element[matcher] rescue nil }
      else
        boundary_test_proc = proc { |element| element == matcher }
        #raise "I don't know how to split with #{matcher}"
      end
    end

    chunks = []
    current_chunk = []
    
    splits = 0
    max_splits = options[:once] == true ? 1 : options[:max_splits]    

    each do |e|

      if boundary_test_proc.call(e) and (max_splits == nil or splits < max_splits)
        
        if current_chunk.empty? and not include_boundary 
          next # hit 2 boundaries in a row... just keep moving, people!
        end
        
        if options[:after]
          # split after boundary
          current_chunk << e        if include_boundary   # include the boundary, if necessary
          chunks << current_chunk                         # shift everything after the boundary into the resultset
          current_chunk = []                              # start a new result
        else
          # split before boundary
          chunks << current_chunk                         # shift before the boundary into the resultset
          current_chunk = []                              # start a new result
          current_chunk << e        if include_boundary   # include the boundary, if necessary
        end

        splits += 1
        
      else
        current_chunk << e
      end

    end
    
    chunks << current_chunk if current_chunk.any?

    chunks # resultset
  end

  #
  # Split the array into chunks, cutting between the matched element and the next element.
  #
  # Example:
  #   [1,2,3,4].split_after{|e| e == 3 } #=> [ [1,2,3], [4] ]
  #
  def split_after(matcher=nil, options={}, &block)
    options[:after]             ||= true
    options[:include_boundary]  ||= true
    split_at(matcher, options, &block)
  end

  #
  # Split the array into chunks, cutting between the matched element and the previous element.
  #
  # Example:
  #   [1,2,3,4].split_before{|e| e == 3 } #=> [ [1,2], [3,4] ]
  #
  def split_before(matcher=nil, options={}, &block)
    options[:include_boundary]  ||= true
    split_at(matcher, options, &block)
  end

  #
  # Sum the elements
  #  
  def sum
    if block_given?
      inject(0) { |total,elem| total + yield(elem) }    
    else
      inject(0) { |total,elem| total + elem }
    end
  end
  
  #
  # Average the elements
  #
  def average
    count = 0
    sum = inject(0) { |total,n| count += 1; total + n }
    sum / count.to_f
  end

  #
  # The same as "map", except that if an element is an Array or Enumerable, map is called
  # recursively on that element.
  #
  # Example:
  #   [ [1,2], [3,4] ].map_recursively{|e| e ** 2 } #=> [ [1,4], [9,16] ] 
  #
  def recursive_map(*args, &block)
    map(*args) do |e|
      if e.is_a? Array or e.is_a? Enumerable
        e.map(*args, &block)
      else
        block.call(e)
      end
    end
  end
  
  alias_method :map_recursively,  :recursive_map
  alias_method :map_recursive,    :recursive_map 


  #
  # Identical to "reduce" in ruby1.9 (or foldl in haskell.)
  #
  # Example:
  #   array.foldl{|a,b| a + b } == array[1..-1].inject(array[0]){|a,b| a + b }
  #
  def foldl(methodname=nil, &block)
    result = nil

    raise "Error: pass a parameter OR a block, not both!" unless !!methodname ^ block_given?
      
    if methodname
      
      each_with_index do |e,i|
        if i == 0
          result = e 
          next
        end
        
        result = result.send(methodname, e)      
      end
      
    else
      
      each_with_index do |e,i|
        if i == 0
          result = e 
          next
        end
        
        result = block.call(result, e)      
      end
      
    end
    
    result
  end

  #
  # Returns the powerset of the Enumerable
  #
  # Example:
  #   [1,2].powerset #=> [[], [1], [2], [1, 2]]
  #
  def powerset
    # the bit pattern of the numbers from 0..2^(elements)-1 can be used to select the elements of the set...
    a = to_a
    (0...2**a.size).map do |bitmask|
      a.select.with_index{ |e, i| bitmask[i] == 1 }
    end
  end

  #
  # Does the opposite of #zip -- converts [ [:a, 1], [:b, 2] ] to [ [:a, :b], [1, 2] ]
  #  
  def unzip
    # TODO: make it work for arrays containing uneven-length contents
    to_a.transpose
  end
  
  #
  # Associative grouping; groups all elements who share something in common with each other.
  # You supply a block which takes two elements, and have it return true if they are "neighbours"
  # (eg: belong in the same group). 
  #
  # Example:
  #   [1,2,5,6].group_neighbours_by { |a,b| b-a <= 1 } #=> [ [1,2], [5,6] ]
  #
  # (Note: This is a very fast one-pass algorithm -- therefore, the groups must be pre-sorted.)
  #
  def group_neighbours_by(&block)
    result = []
    cluster = [first]
    each_cons(2) do |a,b|
      if yield(a,b)
        cluster << b
      else
        result << cluster
        cluster = [b]
      end
    end
    
    result << cluster if cluster.any?
    
    result    
  end
  alias_method :group_neighbors_by, :group_neighbours_by 
  
end


class Object
  
  #
  # Gives you a copy of the object with its attributes changed to whatever was
  # passed in the options hash.
  #
  # Example:
  #   >> cookie = Cookie.new(:size=>10, :chips=>200)
  #   => #<Cookie:0xffffffe @size=10, @chips=200>
  #   >> cookie.with(:chips=>50)
  #   => #<Cookie:0xfffffff @size=10, @chips=50>
  #
  # (All this method does is dup the object, then call "key=(value)" for each
  # key/value in the options hash.)
  #  
  def with(options={})
    obj = dup
    options.each { |key, value| obj.send "#{key}=", value }
    obj
  end

  
  #
  # Return a copy of the class with modules mixed into it.
  #
  def self.using(*args)
    if block_given?
      yield using(*args)
    else
      copy = self.dup
      args.each { |arg| copy.send(:include, arg) }
      copy
    end
  end
  
  
  #
  # Instead of:
  #   if cookie_jar.include? cookie
  # Now you can do:
  #   if cookie.in? cookie_jar
  #
  def in?(enumerable)
    enumerable.include? self
  end

  #
  # Instead of:
  #   @person ? @person.name : nil
  # Now you can do:
  #   @person.try(:name)
  #
  def try(method, *args, &block)
    send(method, *args, &block) if respond_to? method
  end

  #
  # Benchmark a block!
  #
  def bench(message=nil)
    start = Time.now
    result = yield
    elapsed = Time.now - start
    
    print "[#{message}] " if message
    puts "elapsed time: %0.5fs" % elapsed
    result
  end
  alias time bench
  

  #
  # A decorator that makes any block-accepting method return an
  # Enumerator whenever the method is called without a block.
  #  
  def self.enumerable *meths
    meths.each do |meth|
      alias_method "#{meth}_without_enumerator", meth
      class_eval %{
        def #{meth}(*args, &block)
          return Enum.new(self, #{meth.inspect}, *args, &block) unless block_given?
          #{meth}_without_enumerator(*args, &block)
        end
      }
    end
  end

end



class Hash

  #
  # 'true' if the Hash has no entries
  #
  def blank?
    not any?
  end
  
  #
  # Runs "remove_blank_values" on self.
  #  
  def remove_blank_values!
    delete_if{|k,v| v.blank?}
    self
  end
  
  #
  # Returns a new Hash where blank values have been removed.
  # (It checks if the value is blank by calling #blank? on it)
  #
  def remove_blank_values
    dup.remove_blank_values!
  end
  
  #
  # Runs map_values on self. 
  #  
  def map_values!(&block)
    keys.each do |key|
      value = self[key]
      self[key] = yield(value)
    end
    self
  end
  
  #
  # Transforms the values of the hash by passing them into the supplied
  # block, and then using the block's result as the new value.
  #
  def map_values(&block)
    dup.map_values!(&block)
  end

  #
  # Runs map_keys on self.
  #  
  def map_keys!(&block)
    keys.each do |key|
      value = delete(key)
      self[yield(key)] = value
    end
    self
  end
  
  #
  # Transforms the keys of the hash by passing them into the supplied block,
  # and then using the blocks result as the new key.
  #
  def map_keys(&block)
    dup.map_keys!(&block)
  end

  #
  # Returns a new Hash whose values default to empty arrays. (Good for collecting things!)
  #
  # eg:
  #   Hash.of_arrays[:yays] << "YAY!"
  #
  def self.of_arrays
    new {|h,k| h[k] = [] }
  end

  #
  # Returns a new Hash whose values default to 0. (Good for counting things!)
  #
  # eg:
  #   Hash.of_integers[:yays] += 1
  #
  def self.of_integers
    new(0)
  end

  #
  # Makes each element in the `path` array point to a hash containing the next element in the `path`.
  # Useful for turning a bunch of strings (paths, module names, etc.) into a tree.
  #
  # Example:
  #   h = {}
  #   h.mkdir_p(["a", "b", "c"])    #=> {"a"=>{"b"=>{"c"=>{}}}}
  #   h.mkdir_p(["a", "b", "whoa"]) #=> {"a"=>{"b"=>{"c"=>{}, "whoa"=>{}}}}
  #
  def mkdir_p(path)
    return if path.empty?
    dir = path.first
    self[dir] ||= {}
    self[dir].mkdir_p(path[1..-1])
    self
  end
  
  #
  # Turn some nested hashes into a tree (returns an array of strings, padded on the left with indents.)
  #
  def tree(level=0, indent="  ")
    result = []
    dent = indent * level
    each do |key, val|
      result << dent+key
      result += val.tree(level+1) if val.any?
    end
    result
  end  
  
  #
  # Print the result of `tree`
  #
  def print_tree
    tree.each { |row| puts row }
    nil
  end  
  
  #
  # Convert the hash into a GET query.
  #
  def to_query
    params = ''
    stack = []
  
    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      else
        params << "#{k}=#{v}&"
      end
    end
  
    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end
  
    params.chop! # trailing &
    params
  end
  
end

unless defined?(BasicObject)
  #
  # A BasicObject class for Ruby 1.8  
  #
  class BasicObject
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end
end



class NotWrapper < BasicObject # :nodoc:
  def initialize(orig)
    @orig = orig
  end
  
  def inspect
    "{NOT #{@orig.inspect}}"
  end
  
  def method_missing(meth, *args, &block)
    result = @orig.send(meth, *args, &block)
    if result.is_a? ::TrueClass or result.is_a? ::FalseClass
      !result
    else
      raise "Sorry, I don't know how to invert #{result.inspect}"
    end
  end
end

class Object
  
  #
  # Negates a boolean, chained-method style.
  #
  # Example:
  #   >> 10.even?
  #   => true
  #   >> 10.not.even?
  #   => false
  #
  def not
    NotWrapper.new(self)
  end
  
end

# Metaclass 
class Object
  # The hidden singleton lurks behind everyone
  def metaclass
    class << self
      self
    end
  end

  def meta_eval &blk
    metaclass.instance_eval &blk
  end

  # Adds methods to a metaclass
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end
end

unless IO.respond_to? :copy_stream
  
  class IO
    
    def self.copy_stream(input, output)
      while chunk = input.read(8192)
        output.write(chunk)
      end
    end
    
  end
  
end

#
# Emit a quick debug message (only if $DEBUG is true)
#
def dmsg(msg)
  if $DEBUG
    case msg
    when String
      puts msg
    else
      puts msg.inspect
    end
  end
end


def del(x)
  case thing
    when String
      del(x.to_sym)
    when Class, Module
      Object.send(:remove_const, x)
    when Method
      x.owner.send(:undef_method, x.name)
    when Symbol
      if Object.const_get(x)
        Object.send(:remove_const, x)
      elsif method(x)
        undef_method x
      end
    else
      raise "Error: don't know how to 'del #{x.inspect}'"
  end
end
