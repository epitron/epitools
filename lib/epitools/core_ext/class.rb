class Class

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
  # Trace the specified method calls (`meths`, as symbols) to descendends of this class (or all methods if `:*` is supplied).
  # Output is printed to $stderr.
  #
  def trace_messages_to(*meths)
    return unless $DEBUG
    
    tracers = Module.new
    parent  = self

    $stderr.puts "[*] Tracing messages sent to #{parent} (messages: #{meths.join(", ")})"
    
    meths.each do |meth|
      case meth
      when :*
        tracers.define_method(:send) do |meth, *args, &block|
          p meth, args, block
          super(meth, *args, &block)
        end
      else
        tracers.define_method(meth) do |*args, &block|
          args = args.map(&:inspect)
          args << "&block" if block
          $stderr.puts "[*] #{parent}##{meth}(#{args.join(", ")})"
          if block
            super(*args, &block)
          else
            super(*args)
          end
        end
      end
    end

    self.prepend(tracers)
  end


end