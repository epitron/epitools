class Class

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
          arg_names = args.map(&:inspect)
          arg_names << "&block" if block
          $stderr.puts "[*] #{parent}##{meth}(#{arg_names.join(", ")})"
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