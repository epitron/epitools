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
  def with(options={})
    obj = dup
    options.each { |key, value| obj.send "#{key}=", value }
    obj
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
          return Enum.new(self, #{meth.inspect}, *args, &block) unless block_given?
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
  # Instead of:
  #   @person ? @person.name : nil
  # Now you can do:
  #   @person.try(:name)
  #
  def try(method, *args, &block)
    send(method, *args, &block) if respond_to? method
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
  # Proper grammar.
  #  
  alias_method :is_an?, :is_a?
  alias_method :responds_to?, :respond_to?

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
  
end


