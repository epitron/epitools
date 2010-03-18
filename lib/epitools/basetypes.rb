require 'pp'

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
      boundary_test = block
    else
      if matcher.is_a? String or matcher.is_a? Regexp
        boundary_test = proc { |e| e[matcher] }
      else
        raise "I don't know how to split with #{matcher}"
      end
    end

    chunks = []
    current_chunk = []

    each do |e|

      if boundary_test.call(e)
        
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

  alias_method :split, :split_at
  
  #
  # Split the array into chunks, with the boundaries being after the element to split on.
  #
  # eg: [1,2,3,4].split_after{|e| e == 3 } #=> [ [1,2,3], [4] ]
  #
  def split_after(matcher=nil, options={}, &block)
    options[:after]             ||= true
    options[:include_boundary]  ||= true
    split(matcher, options, &block)
  end

  #
  # Split the array into chunks. The boundaries will lie before the element to split on.
  #
  # eg: [1,2,3,4].split_before{|e| e == 3 } #=> [ [1,2], [3,4] ]
  #
  def split_before(matcher=nil, options={}, &block)
    options[:include_boundary]  ||= true
    split(matcher, options, &block)
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
  def try(method)
    send method if respond_to? method
  end

  def bench(message=nil)
    start = Time.now
    yield
    elapsed = Time.now - start
    
    print "[#{message}] " if message
    puts "elapsed time: %0.5fs" % elapsed 
  end
  alias time bench
  
end



class Hash
  def nonblank!
    delete_if{|k,v| v.blank?}
    self
  end
  
  def nonblank
    dup.nonblank!
  end
  
  def map_values!(&block)
    keys.each do |key|
      value = self[key]
      self[key] = yield(value)
    end
    self
  end
  
  def map_values(&block)
    dup.map_values!(&block)
  end
  
  def map_keys!(&block)
    keys.each do |key|
      value = delete(key)
      self[yield(key)] = value
    end
    self
  end
  
  def map_keys(&block)
    dup.map_keys!(&block)
  end

  # TODO: Where did slice come from?
  #alias_method :filter, :slice
  #alias_method :filter!, :slice!
  
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
  def it() It.new end
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


