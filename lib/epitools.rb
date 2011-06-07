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
  
end

#
# Patch 'Module#const_missing' to support 'autoreq'
#
class Module

  @@autoreq_searching_for = nil
  
  alias const_missing_without_autoreq const_missing
  
  def const_missing(const)
    return if const == @@autoreq_searching_for
    
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
    
    @@autoreq_searching_for = const
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

## Require the tools
%w[
  autoloads
  basetypes 
  niceprint
  string_to_proc
  zopen
  colored
  clitools
  permutations
  numwords
].each do |mod|
  require_wrapper.call mod
end

