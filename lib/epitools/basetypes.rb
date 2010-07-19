require 'pp'

# Alias "Enumerable::Enumerator" to "Enum"
Object.const_set(:Enum, Enumerable::Enumerator) rescue nil

class Object
  # Default "integer?" behaviour.
  def integer?; false; end
end

class Float
  def integer?; true; end
end

class String
  
  #
  # Could this string be cast to an integer?
  #
  def integer?
    self.strip.match(/^\d+$/) ? true : false
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
    self.split("\n").map(&:strip).select(&:any?)
  end
  
  alias_method :clean_lines, :nice_lines
  
end

class Integer
  
  def integer?
    true
  end
    
  def to_hex
    "%0.2x" % self
  end
    
  #
  # Convert the number to an array of bits (least significant digit first).
  #
  def to_bits
    ("%b" % self).reverse.chars.map(&:to_i)
  end
  
  alias_method :bits, :to_bits
  
end


class Array
  
  #
  # flatten.compact.uniq
  #
  def squash
    flatten.compact.uniq
  end
  
end


module Enumerable

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
  # eg: [1,2,3,4].split_after{|e| e == 3 } #=> [ [1,2,3], [4] ]
  #
  def split_after(matcher=nil, options={}, &block)
    options[:after]             ||= true
    options[:include_boundary]  ||= true
    split_at(matcher, options, &block)
  end

  #
  # Split the array into chunks. The boundaries will lie before the element to split on.
  #
  # eg: [1,2,3,4].split_before{|e| e == 3 } #=> [ [1,2], [3,4] ]
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
  # eg: [ [1,2], [3,4] ].map_recursive{|e| e ** 2 } #=> [ [1,4], [9,16] ] 
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
  
  alias_method :map_recursive,    :recursive_map 
  alias_method :map_recursively,  :recursive_map


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
    (0...2**size).map do |bitmask|
      select.with_index{ |e, i| bitmask[i] == 1 }
    end
  end

end

class Object

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
  # Enumerable::Enumerator whenever the method is called without a block.
  #  
  def self.enumerable *meths
    meths.each do |meth|
      alias_method "#{meth}_without_enumerator", meth
      class_eval %{
        def #{meth}(*args, &block)
          return Enumerable::Enumerator.new(self, #{meth.inspect}, *args, &block) unless block_given?
          #{meth}_without_enumerator(*args, &block)
        end
      }
    end
  end

end


class Hash

  #
  # Runs remove_blank_lines on self. 
  #  
  def remove_blank_values!
    delete_if{|k,v| v.blank?}
    self
  end
  
  #
  # Returns a new Hash where all elements whose values are "blank?" (eg: "", [], nil)
  # have been eliminated.
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
  # Returns a Hash whsoe values have been transformed by the block.
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
  # Returns a new Hash whose keys have been transformed by the block.
  #
  def map_keys(&block)
    dup.map_keys!(&block)
  end

  #
  # Creates an new Hash whose missing items default to [].
  # Good for collecting things!
  #
  # eg:
  #   Hash.of_arrays[:yays] << "YAY!"
  #
  def self.of_arrays
    new {|h,k| h[k] = [] }
  end

  #
  # Creates an new Hash whose missing items default to values of 0.
  # Good for counting things!
  #
  # eg:
  #   Hash.of_integers[:yays] += 1
  #
  def self.of_integers
    new(0)
  end
  
end



#
# Magic "its" Mapping
# -------------------
#
# The pure-Ruby way:
#   User.find(:all).map{|x| x.contacts.map{|y| y.last_name.capitalize }}
#
# With Symbol#to_proc:
#   User.find(:all).map{|x|x.contacts.map(&:last_name).map(&:capitalize)}
#
# Magic "its" way:
#   User.find(:all).map &its.contacts.map(&its.last_name.capitalize)
#

module Kernel

protected
  def it() 
    It.new 
  end
  
  alias its it
  
end

class It
  undef_method( *(instance_methods - ["__id__", "__send__"]) )

  def initialize
    @methods = []
  end

  def method_missing(*args, &block)
    @methods << [args, block] unless args == [:respond_to?, :to_proc]
    self
  end

  def to_proc
    lambda do |obj|
      @methods.inject(obj) do |current,(args,block)|
        current.send(*args, &block)
      end
    end
  end
end


class BlankSlate
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }
end

#
# Funky #not method
# -----------------
#
# >> 10.even?
# => true
# >> 10.not.even?
# => false
#

class NotWrapper < BlankSlate
  def initialize(orig)
    @orig = orig
  end
  
  def inspect
    "{NOT #{@orig.inspect}}"
  end
  
  def method_missing(meth, *args, &block)
    result = @orig.send(meth, *args, &block)
    if result.is_a? TrueClass or result.is_a? FalseClass
      !result
    else
      raise "Sorry, I don't know how to invert #{result.inspect}"
    end
  end
end


class Object
  def not
    NotWrapper.new(self)
  end
end


