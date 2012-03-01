require 'pp'
require 'set'

class Object

  unless defined?(__DIR__)
    # 
    # This method is convenience for the `File.expand_path(File.dirname(__FILE__))` idiom.
    # (taken from Michael Fellinger's Ramaze... thanx, dood! :D)
    #
    def __DIR__(*args)
      filename = caller[0][/^(.*):/, 1]
      dir = File.expand_path(File.dirname(filename))
      ::File.expand_path(::File.join(dir, *args.map{|a| a.to_s}))
    end
  end
  
  #
  # 'autoreq' is a replacement for autoload that can load gems.
  #
  # Usage:
  #    autoreq :Constant, 'thing-to-require'
  #    autoreq :Constant, 'thing-to-require'
  #    autoreq :OtherConstant do
  #      gem 'somegem', '~> 1.2'
  #      require 'somegem'
  #    end
  #
  def autoreq(const, path=nil, &block)
    raise "Error: autoreq must be supplied with a file to load, or a block." unless !!path ^ block_given?
    
    if block_given?
      Module.autoreqs[const] = block
    else
      Module.autoreqs[const] = path
    end
  end

  #
  # Remove an object, method, constant, etc.
  #
  def del(x)
    case x
      when String
        del(x.to_sym)
      when Class, Module
        Object.send(:remove_const, x.name)
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

#
# Patch 'Module#const_missing' to support 'autoreq' (which can autoload gems)
#
class Module

  @@autoreq_is_searching_for = nil
  
  alias const_missing_without_autoreq const_missing
  
  def const_missing(const)
    return if const == @@autoreq_is_searching_for
    
    if thing = autoreqs[const]
      case thing
      when String, Symbol
        require thing
      when Proc
        Object.class_eval(&thing)
      else
        raise "Error: Don't know how to autoload a #{thing.class}: #{thing.inspect}"
      end
    end
    
    @@autoreq_is_searching_for = const
    const_get(const) || const_missing_without_autoreq(const)
  end
  
  def autoreqs
    @@autoreqs ||= {}
  end
  
end


## Pretty error messages
require_wrapper = proc do |mod|
  #p [:loading, mod]
  begin
    require File.join(__DIR__, "epitools", mod)
  rescue LoadError => e
    puts "* Error loading epitools/#{mod}: #{e}"
  end
end

#
# Make all the modules autoload, and require all the monkeypatches
#
%w[
  autoloads
  core_ext 
  zopen
  colored
  clitools
  permutations
  numwords
].each do |mod|
  require_wrapper.call mod
end

