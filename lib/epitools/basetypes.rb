require 'pp'

# Alias "Enumerator" to "Enum"

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
  def truthy?; not blank?; end

end

class TrueClass
  def truthy?; true; end
end

class FalseClass
  def truthy?; false; end
end

class Numeric
  def integer?; true; end

  def commatize  
    to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
  end
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
  # Like #lines, but skips empty lines and removes \n's.
  #
  def nice_lines
    split("\n").select{|l| not l.blank? }
  end
  
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
    require 'uri' unless defined? URI
    URI.escape(self)
  end
  
  #
  # Convert an URI's %XXes into regular characters.
  #
  def urldecode
    require 'uri' unless defined? URI
    URI.unescape(self)
  end

  #
  # Convert a query string to a hash of params
  #
  def to_params
    require 'cgi' unless defined? CGI
    CGI.parse(self).map_values{|v| v.is_a?(Array) and v.size == 1 ? v.first : v }
  end
  
  #
  # Decode a mime64/base64 encoded string
  #
  def decode64
    require 'base64' unless defined? Base64
    Base64.decode64 self
  end
  
  #
  # Encode into a mime64/base64 string
  #
  def encode64
    require 'base64' unless defined? Base64
    Base64.encode64 self
  end
  alias_method :base64, :encode64

  #
  # MD5 the string
  #  
  def md5
    require 'digest/md5' unless defined? Digest::MD5
    Digest::MD5.hexdigest self
  end
  
  #
  # SHA1 the string
  #  
  def sha1
    require 'digest/sha1' unless defined? Digest::SHA1
    Digest::SHA1.hexdigest self
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
    require 'json' unless defined? JSON
    JSON.parse self
  end
  
end


class Integer
  
  #
  # 'true' if the integer is 0
  #
  def blank?; self == 0; end

  #
  # Convert the number into a hexadecimal string representation.
  #
  def to_hex
    "%0.2x" % self
  end
    
  #
  # Convert the number to an array of bits (least significant digit first, or little-endian).
  #
  def to_bits
    ("%b" % self).chars.to_a.reverse.map(&:to_i)
  end
  
  alias_method :bits, :to_bits
  
end


#
# Monkeypatch [] into Bignum and Fixnum using class_eval.
#
# (This is necessary because [] is defined directly on the classes, and a mixin
#  module will still be overridden by Big/Fixnum's native [] method.)
#
[Bignum, Fixnum].each do |klass|
  
  klass.class_eval do
    
    alias_method :bit, :[]
    
    #
    # Extends [] so that Integers can be sliced as if they were arrays.
    #
    def [](arg)
      case arg
      when Integer
        bit(arg)
      when Range
        bits[arg]
      end
    end
    
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
  
end


module Enumerable

  #
  # 'true' if the Enumerable has no elements
  #
  def blank?
    not any?
  end
  
  #
  # Split this enumerable into an array of pieces given some 
  # boundary condition.
  #
  # Options:
  #   :include_boundary => true  #=> include the element that you're splitting at in the results  
  #                                  (default: false)
  #   :after => true             #=> split after the matched element (only has an effect when used with :include_boundary)  
  #                                  (default: false)
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
  # TODO:
  #   - Ruby 1.9 returns Enumerators for everything now. Maybe do that?
  #
  def split_at(matcher=nil, options={}, &block)
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

    each do |e|

      if boundary_test_proc.call(e)
        
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
        
      else
        current_chunk << e
      end

    end
    
    chunks << current_chunk if current_chunk.any?

    chunks # resultset
  end

  #
  # Split the array into chunks, with the boundaries being after the element to split on.
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
  # Split the array into chunks. The boundaries will lie before the element to split on.
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
    inject(0) { |total,n| total + n }
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

    raise "Error: pass a parameter OR a block, not both!" if methodname and block
      
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
    yield
    elapsed = Time.now - start
    
    print "[#{message}] " if message
    puts "elapsed time: %0.5fs" % elapsed 
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


