class Object

  #
  # Return a hash of local variables in the caller's scope: {:variable_name=>value}
  #
  def locals
    require 'binding_of_caller'
    caller = binding.of_caller(1)
    vars = caller.eval("local_variables").reject{|e| e[/^_/]}
    vals = caller.eval("[ #{vars.join(",")} ]")
    Hash[ vars.zip(vals) ]
  end


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
  # == BONUS FEATURE! ==
  #
  # If you supply a block, it just gives you the object, and
  # returns whatever your block returns.
  #
  # Example:
  #   >> {a: 10, b: 2}.with { |hash| hash[:a] / hash[:b] }
  #   => 5
  #
  # Good for chaining lots of operations together in a REPL.
  #
  def with(options={})
    if block_given?
      yield self
    else
      obj = dup
      options.each { |key, value| obj.send "#{key}=", value }
      obj
    end
  end


  #
  # Creates attr_accessors and an initialize method
  # that accepts the attrs as arguments.
  # (It's kinda like an inline version of Struct.new(*args))
  #
  def self.attrs(*names)
    attr_accessor *names
    define_method :initialize do |*vals|
      names.zip(vals) do |name, val|
        instance_variable_set("@#{name}", val)
      end
    end
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
  # Serialize this object to a binary String, using Marshal.dump.
  #
  def marshal
    Marshal.dump self
  end
  alias_method :to_marshal, :marshal

  #
  # Serialize this object to YAML.
  #
  def to_yaml
    YAML::dump(self)
  end

  #
  # Serialize this object to JSON (defaults to "pretty" indented JSON).
  #
  def to_json(pretty=true)
    pretty ? JSON::pretty_generate(self) : JSON.dump(self)
  end

  #
  # Emit a quick debug message (only if $DEBUG is true)
  #
  def dmsg(msg)
    if $DEBUG
      case msg
      when String
        puts msg
      else
        puts msg.inspect
      end
    end
  end

  #
  # Time a block.
  #
  def time(message=nil)
    start = Time.now
    result = yield
    elapsed = Time.now - start

    print "[#{message}] " if message
    puts "elapsed time: %0.5fs" % elapsed
    result
  end

  #
  # Quick and easy benchmark.
  #
  # Examples:
  #   bench { something }
  #   bench(90000000) { something }
  #   bench :fast => proc { fast_method }, :slow => proc { slow_method }
  #
  # In Ruby 1.9:
  #   bench fast: ->{ fast_method }, slow: ->{ slow_method }
  #
  def bench(*args, &block)

    # Shitty perl-esque hack to let the method take all the different kind of arguments.
    opts  = Hash === args.last ? args.pop : {}
    n     = args.first || 100

    if opts.any?

      raise "Error: Supply either a do/end block, or procs as options. Not both." if block_given?
      raise "Error: Options must be procs." unless opts.all? { |k, v| v.is_a?(Proc) }

      benchblock = proc do |bm|
        opts.each do |name, blk|
          bm.report(name.to_s) { n.times &blk }
        end
      end

    elsif block_given?

      benchblock = proc do |bm|
        bm.report { n.times &block }
      end

    else
      raise "Error: Must supply some code to benchmark."
    end

    puts "* Benchmarking #{n} iterations..."
    Benchmark.bmbm(&benchblock)
  end

  def present?
    true
  end


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


class Module

  #
  # Cache (memoize) the result of an instance method the first time
  # it's called, storing this value in the "@__memoized_#{methodname}_cache"
  # instance variable, and always return this value on subsequent calls
  # (unless the returned value is nil).
  #
  def memoize(*methods)
    # alias_method is faster than define_method + old.bind(self).call
    methods.each do |meth|
      alias_method "__memoized__#{meth}", meth
      module_eval <<-EOF
        def #{meth}(*a, &b)
          # assumes the block won't change the result if the args are the same
          (@__memoized_#{meth}_cache ||= {})[a] ||= __memoized__#{meth}(*a, &b)
        end
      EOF
    end
  end

end  