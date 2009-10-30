require 'pp'

class String
  def integer?; self.strip.match(/^\d+$/) ? true : false; end
  def nice_lines; self.split("\n").map(&:strip).select(&:any?); end
end

class Integer
  def integer?; true; end
  def to_hex; "%0.2x" % self; end
end

class NilClass
  def integer?; false; end
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

  def meths
    (methods - Object.new.methods).sort
  end
  
  def pms
    pp meths.map do |methname|
      meth = method(methname)
      "#{methname}" + (meth.arity > 0) ? "(#{meth.arity})" : ""
    end
  end
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

  alias_method :filter, :slice
  alias_method :filter!, :slice!
  
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


