require 'pp'


class String
  
  def integer?; self.strip.match(/^\d+$/) ? true : false; end
    
  #
  # Like #lines, but skips empty lines and removes \n's.
  #
  def nice_lines; self.split("\n").map(&:strip).select(&:any?); end
end


class Integer
  def integer?; true; end
  def to_hex; "%0.2x" % self; end
end


class NilClass
  def integer?; false; end
end


class Array
  def squash
    self.flatten.compact.uniq
  end
end


module Enumerable

  #
  # Split this enumerable into an array of pieces given som 
  # boundary condition.
  #
  # Examples: 
  #   [1,2,3,4,5].split{ |e| e == 3 }                           #=> [ [1,2], [4,5] ] 
  #   [1,2,3,4,5].split(:include_boundary=>true) { |e| e == 3 } #=> [ [1,2], [3,4,5] ] 
  #   chapters = File.read("ebook.txt").split(/Chapter \d+/, :include_boundary=>true)
  #
  def split(matcher=nil, options={}, &block)
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
        next                      if current_chunk.empty?
        chunks << current_chunk
        current_chunk = []
        current_chunk << e        if include_boundary
      else
        current_chunk << e
      end

    end

    chunks
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


