class MatchData

  #
  # Return a hash of named matches
  #
  def to_hash
    Hash[ names.zip(captures) ]
  end

end


class Binding

  #
  # Get a variable in this binding
  #
  def [](key)
    eval(key.to_s)
  end

  #
  # Set a variable in this binding
  #
  def []=(key, val)
    Thread.current[:_alter_binding_local_] = val
    eval("#{key} = Thread.current[:_alter_binding_local_]")
    Thread.current[:_alter_binding_local_] = nil
  end

  #
  # Return all the local variables in the binding
  #
  if RUBY_VERSION["1.8"]
    def local_variables
      eval("local_variables").map(&:to_sym)
    end
  else
    def local_variables
      eval("local_variables")
    end
  end

  alias_method :keys, :local_variables

  #
  # Combine the variables in two bindings (the latter having precedence)
  #
  def merge(other)
    self.eval do
      other.eval do
        binding
      end
    end
  end

  alias_method :|, :merge

end


class Proc

  #
  # Chain two procs together, returning a new proc. Each proc is executed one after the other,
  # with the same input arguments. The return value is an array of all the procs' return values.
  #
  # You can use either the .join method, or the overloaded & operator.
  #
  # Examples:
  #   joined = proc1 & proc2
  #   joined = proc1.join proc2
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
  # Backported BasicObject for Ruby 1.8
  #
  class BasicObject
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
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

class NotWrapper < BasicObject # :nodoc:
  def initialize(orig)
    @orig = orig
  end

  def inspect
    "{NOT #{@orig.inspect}}"
  end

  def is_a?(other)
    other === self
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



unless IO.respond_to? :copy_stream

  class IO

    #
    # IO.copy_stream backport
    #
    def self.copy_stream(input, output)
      while chunk = input.read(8192)
        output.write(chunk)
      end
    end

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

  #
  # Return a Hash of the variables in the query string
  #
  def params
    query.to_params
  end

  #
  # URIs are strings, dammit!
  #
  def to_str
    to_s
  end

end



class Time

  #
  # Which "quarter" of the year does this date fall into?
  #
  def quarter
    (month / 3.0).ceil
  end

end



#
# Give ObjectSpace Enumerable powers (select, map, etc.)
#
module ObjectSpace

  include Enumerable

  alias_method :each, :each_object

  extend self

end

#
# Flush standard input's buffer.
#
def STDIN.purge
  begin
    loop { read_nonblock(4096) }
  rescue Errno::EAGAIN
    # No more input!
  end
end


class DateTime
  def to_i; to_time.to_i; end
  def to_f; to_time.to_f; end
end


class NilClass

  def present?
    false
  end

  def blank?
    true
  end

end

class FalseClass
  def present?
    false
  end
end