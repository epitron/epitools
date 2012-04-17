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
  
end

require 'epitools/core_ext/object'
require 'epitools/core_ext/string'
require 'epitools/core_ext/array'
require 'epitools/core_ext/enumerable'
require 'epitools/core_ext/hash'
require 'epitools/core_ext/numbers'
require 'epitools/core_ext/truthiness'


class MatchData

  #
  # Return a hash of named matches
  #
  def to_hash
    Hash[ names.zip(captures) ]
  end
  
end


class Binding

  def [](key)
    eval(key.to_s)
  end
  
  def []=(key, val)
    Thread.current[:_alter_binding_local_] = val
    eval("#{key} = Thread.current[:_alter_binding_local_]")
    Thread.current[:_alter_binding_local_] = nil
  end

  def local_variables
    eval("local_variables")
  end
  alias_method :keys, :local_variables

end


class Proc

  #
  # Joins two procs together, returning a new proc.
  #
  # Example:
  #   newproc = proc { 1 } & proc { 2 }
  #   newproc.call #=> [1, 2]
  #
  def join(other=nil, &block)
    other ||= block
    proc { |*args| [self.call(*args), other.call(*args)] }
  end
  alias_method :&, :join
  
  #
  # Chains two procs together, returning a new proc. The output from each proc is passed into
  # the input of the next one.
  #
  # Example:
  #   chain = proc { 1 } | proc { |input| input + 1 }
  #   chain.call #=> 2
  #
  def chain(other=nil, &block)
    other ||= block
    proc { |*args| other.call( self.call(*args) ) }
  end
  alias_method :|, :chain 
  
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

unless IO.respond_to? :copy_stream
  
  class IO
    
    def self.copy_stream(input, output)
      while chunk = input.read(8192)
        output.write(chunk)
      end
    end
    
  end
  
end


class Range

  #
  # Pick a random number from the range.
  #
  def rand
    Kernel.rand(self)
  end

end


class Struct

  #
  # Transform this struct into a JSON hash
  #
  def to_hash
    hash = {}
    each_pair { |k,v| hash[k] = v }
    hash
  end

  #
  # Transform the struct into a simple JSON hash.
  #
  def to_json(*args)
    to_hash.to_json
  end

end


module URI

  def params
    query.to_params
  end

end