#
# If you require 'epitools/minimal' instead of 'epitools',
# this is what you get: core_ext monkeypatches and all the
# autoloads; the barest essentials for survival.
#

if RUBY_VERSION[/^1.8/]
  require 'enumerator'
  Enumerator = Enumerable::Enumerator unless defined? Enumerator
end

RbConfig = Config unless defined? RbConfig

Infinity = Float::INFINITY
Inf      = Float::INFINITY

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
  if defined? singleton_class
    alias metaclass singleton_class
  else
    def metaclass
      class << self
        self
      end
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

  #
  # Slightly gross hack to add a class method.
  #
  def self.alias_class_method(dest, src)
    metaclass.send(:alias_method, dest, src)
  end

  #
  # Turns block-accepting iterator methods (eg: each) into methods that return an
  # Enumerator when they're called called without a block.
  #
  # It can transform many methods at once (eg: `enumerable :each, :all_people`).
  #
  # Example:
  #
  #   def lots_of_stuff
  #     @stuff.each { |thing| yield thing }
  #   end
  #
  #   enumerable :lots_of_stuff
  #
  # Now you can use it like an Enumerator: object.lots_of_stuff.with_index.sort.zip(99..1000)
  #
  def self.enumerable *meths
    meths.each do |meth|
      alias_method "#{meth}_without_enumerator", meth
      class_eval %{
        def #{meth}(*args, &block)
          return to_enum(#{meth.inspect}, *args, &block) unless block_given?
          #{meth}_without_enumerator(*args, &block)
        end
      }
    end
  end
  alias_class_method :enumerator, :enumerable

  #
  # Instead of:
  #   if cookie_jar.include? cookie
  # Now you can do:
  #   if cookie.in? cookie_jar
  #
  def in?(enum)
    enum.include? self
  end

  #
  # Proper grammar.
  #
  alias_method :is_an?, :is_a?
  alias_method :responds_to?, :respond_to?

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
  # Return this object. If given a block, yields this object
  # and returns the result of the block.
  #
  # eg: stuff.group_by(&:self)
  #
  define_method :self do
    if block_given?
      yield self
    else
      self
    end
  end
  alias_method :fap, :self

  def ancestors
    self.class.ancestors
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


module Kernel

  #
  # Executes a command and returns its output. (Like the backtick operator,
  # but doesn't require shell ecaping arguments.)
  #
  def run(*cmd)
    result = IO.popen(cmd) do |io|
      block_given? ? yield(io) : io.read
    end
    String === result && result.empty? ? nil : result
  end
  alias_method :backtick, :run

  #
  # Same as Kernel#run, but includes stderr in the result.
  #
  def run_with_stderr(*cmd)
    result = IO.popen(cmd, err: [:child, :out]) do |io|
      block_given? ? yield(io) : io.read
    end
    String === result && result.empty? ? nil : result
  end
  alias_method :backtick_with_stderr, :run_with_stderr

  #
  # Print "self" with a linefeed at the end
  #
  def displayln(out=$stdout)
    out.puts self
  end

end


class String

  #
  # Convert the string to a Path object (for representing files/directories).
  #
  def to_Path
    Path[self]
  end
  alias_method :to_P, :to_Path

end

#
# Path("/some/path") is an alias for Path["/some/path"]
#
def Path(arg)
  Path[arg]
end

####################################################################

# class << ARGV

#   def opts
#     @opts, @args ||= partition { |arg| arg[/^--?\w{1,2}/].nil? }
#   end

#   def args
#     @args ? @args : opts && @args
#   end

#   def paths
#     map(&:to_Path)
#   end

#   def paths_R
#     recursive_proc = proc do |paths|
#       paths.map { |path| path.dir? ? the_expander.(path.ls_R) : path }
#     end

#     recursive_proc.(paths)
#   end
#   alias_method :recursive_paths, :paths_R

#   def regexes(escaped: true, case_sensitive: false)
#     if case_sensitive
#       map { |arg| /#{escaped ? Regexp.escape(arg) : arg}/ } # NO 'i'
#     else
#       map { |arg| /#{escaped ? Regexp.escape(arg) : arg}/i }
#     end
#   end

# end

####################################################################

require 'epitools/autoloads'

####################################################################
