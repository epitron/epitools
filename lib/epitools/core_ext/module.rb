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