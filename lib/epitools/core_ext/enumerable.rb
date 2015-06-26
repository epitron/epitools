module Enumerable

  #
  # 'true' if the Enumerable has no elements
  #
  def blank?
    not any?
  end

  #
  # `.all` is more fun to type than `.to_a`
  #
  alias_method :all, :to_a

  #
  # `includes?` is gramatically correct.
  #
  alias_method :includes?,  :include?

  #
  # Skip the first n elements and return an Enumerator for the rest, or pass them
  # in succession to the block, if given. This is like "drop", but returns an enumerator
  # instead of converting the whole thing to an array.
  #
  def skip(n)
    if block_given?
      each do |x|
        if n > 0
          n -= 1
        else
          yield x
        end
      end
    else
      to_enum(:skip, n)
    end
  end

  #
  # Add reverse_each to old Ruby versions
  #
  unless defined? reverse_each
    def reverse_each
      to_a.to_enum(:reverse_each)
    end
  end

  #
  # Split this enumerable into chunks, given some boundary condition. (Returns an array of arrays.)
  #
  # Options:
  #   :include_boundary => true  #=> include the element that you're splitting at in the results
  #                                  (default: false)
  #   :after => true             #=> split after the matched element (only has an effect when used with :include_boundary)
  #                                  (default: false)
  #   :once => flase             #=> only perform one split (default: false)
  #
  # Examples:
  #   [1,2,3,4,5].split{ |e| e == 3 }
  #   #=> [ [1,2], [4,5] ]
  #
  #   [1,2,3,4,5].split(:include_boundary=>true) { |e| e == 3 }
  #   #=> [ [1,2], [3,4,5] ]
  #
  #   chapters = File.read("ebook.txt").split(/Chapter \d+/, :include_boundary=>true)
  #   #=> [ ["Chapter 1", ...], ["Chapter 2", ...], etc. ]
  #
  def split_at(matcher=nil, options={}, &block)
    include_boundary = options[:include_boundary] || false

    if matcher.nil?
      boundary_test_proc = block
    else
      if matcher.is_a? String or matcher.is_a? Regexp
        boundary_test_proc = proc { |element| element[matcher] rescue nil }
      else
        boundary_test_proc = proc { |element| element == matcher }
        #raise "I don't know how to split with #{matcher}"
      end
    end

    Enumerator.new do |yielder|
      current_chunk = []
      splits        = 0
      max_splits    = options[:once] == true ? 1 : options[:max_splits]

      each do |e|

        if boundary_test_proc.call(e) and (max_splits == nil or splits < max_splits)

          if current_chunk.empty? and not include_boundary
            next # hit 2 boundaries in a row... just keep moving, people!
          end

          if options[:after]
            # split after boundary
            current_chunk << e        if include_boundary   # include the boundary, if necessary
            yielder << current_chunk                         # shift everything after the boundary into the resultset
            current_chunk = []                              # start a new result
          else
            # split before boundary
            yielder << current_chunk                         # shift before the boundary into the resultset
            current_chunk = []                              # start a new result
            current_chunk << e        if include_boundary   # include the boundary, if necessary
          end

          splits += 1

        else
          current_chunk << e
        end

      end

      yielder << current_chunk if current_chunk.any?

    end
  end

  #
  # Split the array into chunks, cutting between the matched element and the next element.
  #
  # Example:
  #   [1,2,3,4].split_after{|e| e == 3 } #=> [ [1,2,3], [4] ]
  #
  def split_after(matcher=nil, options={}, &block)
    options[:after]             ||= true
    options[:include_boundary]  ||= true
    split_at(matcher, options, &block)
  end

  #
  # Split the array into chunks, cutting before each matched element.
  #
  # Example:
  #   [1,2,3,4].split_before{|e| e == 3 } #=> [ [1,2], [3,4] ]
  #
  def split_before(matcher=nil, options={}, &block)
    options[:include_boundary]  ||= true
    split_at(matcher, options, &block)
  end

  #
  # Split the array into chunks, cutting between two elements.
  #
  # Example:
  #   [1,1,2,2].split_between{|a,b| a != b } #=> [ [1,1], [2,2] ]
  #
  def split_between(&block)
    Enumerator.new do |yielder|
      current = []
      last    = nil

      each_cons(2) do |a,b|
        current << a
        if yield(a,b)
          yielder << current
          current = []
        end
        last = b
      end

      current << last unless last.nil?
      yielder << current
    end
  end

  alias_method :cut_between, :split_between

  #
  # Sum the elements
  #
  def sum(&block)
    if block_given?
      map(&block).reduce(:+)
    else
      reduce(:+)
    end
  end
  alias_method :sum_by, :sum

  #
  # Average the elements
  #
  def average
    count = 0
    sum   = 0

    each { |e| count += 1; sum += e }

    sum / count.to_f
  end

  #
  # The same as "map", except that if an element is an Array or Enumerable, map is called
  # recursively on that element. (Hashes are ignored because of the complications of block
  # arguments and return values.)
  #
  # Example:
  #   [ [1,2], [3,4] ].deep_map{|e| e ** 2 } #=> [ [1,4], [9,16] ]
  #
  def map_recursively(max_depth=nil, current_depth=0, parent=nil, &block)
    return self if max_depth and (current_depth > max_depth)

    map do |obj|
      if obj == parent # infinite loop scenario!
        yield obj
      else
        case obj
        when String, Hash
          yield obj
        when Enumerable
          obj.map_recursively(max_depth, current_depth+1, self, &block)
        else
          yield obj
        end
      end
    end
  end

  alias_method :deep_map,      :map_recursively
  alias_method :recursive_map, :map_recursively
  alias_method :map_recursive, :map_recursively

  #
  # The same as "select", except that if an element is an Array or Enumerable, select is called
  # recursively on that element.
  #
  # Example:
  #   [ [1,2], [3,4] ].select_recursively{|e| e % 2 == 0 } #=> [ [2], [4] ]
  #
  def select_recursively(max_depth=nil, current_depth=0, parent=nil, &block)
    return self if max_depth and (current_depth > max_depth)

    map do |obj|
      if obj == parent # infinite loop scenario!
        obj if yield obj
      else
        case obj
        when String, Hash
          obj if yield obj
        when Enumerable
          obj.deep_select(max_depth, current_depth+1, self, &block)
        else
          obj if yield obj
        end
      end
    end.compact
  end

  alias_method :deep_select,        :select_recursively
  alias_method :recursive_select,   :select_recursively
  alias_method :select_recursive,   :select_recursively

  #
  # Identical to "reduce" in ruby1.9 (or foldl in haskell.)
  #
  # Example:
  #   array.foldl{|a,b| a + b } == array[1..-1].inject(array[0]){|a,b| a + b }
  #
  def foldl(methodname=nil, &block)
    result = nil

    raise "Error: pass a parameter OR a block, not both!" unless !!methodname ^ block_given?

    if methodname

      each_with_index do |e,i|
        if i == 0
          result = e
          next
        end

        result = result.send(methodname, e)
      end

    else

      each_with_index do |e,i|
        if i == 0
          result = e
          next
        end

        result = block.call(result, e)
      end

    end

    result
  end


  #
  # See: Array#permutation
  #
  def permutation(*args, &block)
    to_a.permutation(*args, &block)
  end

  #
  # See: See Array#combination
  #
  def combination(*args, &block)
    to_a.combination(*args, &block)
  end

  #
  # Returns the powerset of the Enumerable
  #
  # Example:
  #   [1,2].powerset #=> [[], [1], [2], [1, 2]]
  #
  def powerset
    # the bit pattern of the numbers from 0..2^(elements)-1 can be used to select the elements of the set...
    a = to_a
    (0...2**a.size).map do |bitmask|
      a.select.with_index{ |e, i| bitmask[i] == 1 }
    end
  end

  #
  # Does the opposite of #zip -- converts [ [:a, 1], [:b, 2] ] to [ [:a, :b], [1, 2] ]
  #
  def unzip
    # TODO: make it work for arrays containing uneven-length contents
    to_a.transpose
  end

  #
  # Associative grouping; groups all elements who share something in common with each other.
  # You supply a block which takes two elements, and have it return true if they are "neighbours"
  # (eg: belong in the same group).
  #
  # Example:
  #   [1,2,5,6].group_neighbours_by { |a,b| b-a <= 1 } #=> [ [1,2], [5,6] ]
  #
  # (Note: This is a very fast one-pass algorithm -- therefore, the groups must be pre-sorted.)
  #
  def group_neighbours_by(&block)
    result = []
    cluster = [first]
    each_cons(2) do |a,b|
      if yield(a,b)
        cluster << b
      else
        result << cluster
        cluster = [b]
      end
    end

    result << cluster if cluster.any?

    result
  end
  alias_method :group_neighbors_by, :group_neighbours_by

  #
  # Convert the array into a stable iterator (Iter) object.
  #
  def to_iter
    Iter.new(to_a)
  end
  alias_method :iter, :to_iter

  #
  # Counts how many instances of each object are in the collection,
  # returning a hash. (Also optionally takes a block.)
  #
  # eg: [:a, :b, :c, :c, :c, :c].counts #=> {:a=>1, :b=>1, :c=>4}
  #
  def counts
    h = Hash.of_integers
    if block_given?
      each { |x| h[yield x] += 1 }
    else
      each { |x| h[x] += 1 }
    end
    h
  end
  alias_method :count_by,     :counts
  alias_method :group_counts, :counts

  #
  # group_by the elements themselves
  #
  def groups
    group_by(&:self)
  end
  alias_method :grouped, :groups

  #
  # Multiplies this Enumerable by something. (Same behaviour as Enumerator#*)
  #
  def *(other)
    case other
    when Integer, String
      to_enum * other
    when Enumerable
      to_enum.cross_product(other)
    end
  end

  #
  # Multiplies this Enumerable by itself `n` times.
  #
  def **(n)
    [self].cycle(n).reduce(:*)
  end

  #
  # Same behaviour as Enumerator#cross_product
  #
  def cross_product(other)
    to_enum.cross_product(other)
  end
  alias_method :cross, :cross_product

end


class Enumerator

  SPINNER = ['-', '\\', '|', '/']

  #
  # Display a spinner every `every` elements that pass through the Enumerator.
  #
  def with_spinner(every=37)
    to_enum do |yielder|
      spins = 0

      each.with_index do |e, i|
        if i % every == 0
          print "\b" unless spins == 0
          print SPINNER[spins % 4]

          spins += 1
        end

        yielder << e
      end

      print "\b \b" # erase the spinner when done
    end
  end


  #
  # Pass in a bunch of indexes to elements in the Enumerator, and this method
  # lazily returns them as a new Enumerator.
  #
  def values_at(*indexes)
    return if indexes.empty?

    indexes.flatten!

    indexes = Set.new(indexes)

    Enumerator.new do |yielder|
      each_with_index do |e,i|
        yielder << e if indexes.delete(i)
        break if indexes.empty?
      end
    end
  end



  #
  # Concatenates two Enumerators, returning a new Enumerator.
  #
  def +(other)
    raise "Can only concatenate Enumerable things to Enumerators" unless Enumerable === other

    Enumerator.new do |yielder|
      each { |e| yielder << e }
      other.each { |e| yielder << e }
    end
  end


  #
  # Multiplies this Enumerator by something else.
  #
  # Enumerator * Integer == a new Enumerator that repeats the original one <Integer> times
  # Enumerator * String == joins the Enumerator's elements into a new string, with <String> in between each pair of elements
  # Enumerator * Enumerable == the cross product (aka. cartesian product) of the Enumerator and the Enumerable
  #
  def *(other)
    case other
    when Integer
      cycle(other)
    when String
      join(other)
    when Enumerable
      cross(other)
    else
      raise "#{other.class} is not something that can be multiplied by an Enumerator"
    end
  end

  #
  # Takes the cross product (aka. cartesian product) of the Enumerator and the argument,
  # returning a new Enumerator. (The argument must be some kind of Enumerable.)
  #
  def cross_product(other)
    Enumerator.new do |yielder|
      each { |a| other.each { |b| yielder << [a,b] } }
    end
  end
  alias_method :cross, :cross_product

end