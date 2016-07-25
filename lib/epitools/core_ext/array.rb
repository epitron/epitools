
class Array

  #
  # Better names
  #
  alias_method :lpush, :unshift
  alias_method :lpop,  :shift

  #
  # flatten.compact.uniq
  #
  def squash
    flatten.compact.uniq
  end

  #def to_hash
  #  Hash[self]
  #end

  #
  # Removes the elements from the array for which the block evaluates to true.
  # In addition, return the removed elements.
  #
  # For example, if you wanted to split an array into evens and odds:
  #
  #   nums = [1,2,3,4,5,6,7,8,9,10,11,12]
  #   even = nums.remove_if { |n| n.even? }   # remove all even numbers from the "nums" array and return them
  #   odd  = nums                             # "nums" now only contains odd numbers
  #
  def remove_if(&block)
    removed = []

    delete_if do |x|
      if yield(x)
        removed << x
        true
      else
        false
      end
    end

    removed
  end

  #
  # zip from the right (or reversed zip.)
  #
  # eg:
  #   >> [5,39].rzip([:hours, :mins, :secs])
  #   => [ [:mins, 5], [:secs, 39] ]
  #
  def rzip(other)
    reverse_each.zip(other.reverse_each).reverse_each
    # reverse.zip(other.reverse).reverse # That's a lotta reverses!
  end

  #
  # See: Enumerable#split_at
  #
  def split_at(*args, &block)
    super.to_a
  end

  #
  # Pick the middle element
  #
  def middle
    self[(size-1) / 2]
  end

  #
  # Find the statistical mean
  #
  def mean
    sum / size.to_f
  end
  alias_method :average, :mean

  #
  # Find the statistical median (middle value in the sorted dataset)
  #
  def median
    sort.middle
  end


  #
  # Find the statistical "mode" (most frequently occurring value)
  #
  def mode
    counts.max_by { |k,v| v }.first
  end

  #
  # XOR operator
  #
  def ^(other)
    (self | other) - (self & other)
  end

  #
  # Shuffle the array
  #
  unless instance_methods.include? :shuffle
    def shuffle
      sort_by { rand }
    end
  end

  #
  # Pick (a) random element(s).
  #
  unless instance_methods.include? :sample
    def sample(n=1)
      return self[rand sz] if n == 1

      sz      = size
      indices = []

      loop do
        indices += (0..n*1.2).map { rand sz }
        indices.uniq
        break if indices.size >= n
      end

      values_at(*indices[0...n])
    end
  end
  alias_method :pick, :sample

  #
  # Divide the array into n pieces.
  #
  def / pieces
    piece_size = (size.to_f / pieces).ceil
    each_slice(piece_size).to_a
  end

  alias_method :unzip, :transpose

  #
  # Convert the array to a hash
  #
  unless defined? [].to_h
    def to_h
      if self.first.is_a? Array
        Hash[self]
      else
        Hash[*self]
      end
    end
  end

  #
  # Takes an array of numbers, puts them into equal-sized
  # buckets, and counts the buckets (aka. A Histogram!)
  #
  # Examples:
  #   [1,2,3,4,5,6,7,8,9].histogram(3) #=> [3,3,3]
  #   [1,2,3,4,5,6,7,8,9].histogram(2) #=> [4,5]
  #   [1,2,3,4,5,6,7,8,9].histogram(2, ranges: true)
  #      #=> {
  #            1.0...5.0 => 4,
  #            5.0...9.0 => 5
  #          }
  #
  def histogram(n_buckets=10, options={})
    
    use_ranges = options[:ranges] || options[:hash]

    min_val     = min
    max_val     = max
    range       = (max_val - min_val)
    bucket_size = range.to_f / n_buckets
    buckets     = [0]*n_buckets

    # p [range, bucket_size, buckets, min_val, max_val]

    each do |e|
      bucket = (e - min_val) / bucket_size
      bucket = n_buckets - 1 if bucket >= n_buckets
      # p [:e, e, :bucket, bucket]
      buckets[bucket] += 1
    end

    if use_ranges
      ranges = (0...n_buckets).map do |n|
        offset = n*bucket_size
        (min_val + offset) ... (min_val + offset + bucket_size)
      end
      Hash[ ranges.zip(buckets) ]
    else
      buckets
    end

  end


  alias_method :old_multiply, :*
  private :old_multiply

  #
  # Overridden multiplication operator. Now lets you multiply the Array by another Array or Enumerable.
  #
  # Array * Integer == a new array with <Integer> copies of itself inside
  # Array * String == a new string containing the elements, joined by the <String>
  # Array * {Array or Enumerable} == the cross product (aka. cartesian product) of both arrays
  #
  def *(other)
    case other
    when Integer, String
      old_multiply(other)
    when Enumerable
      cross_product(other).to_a
    end
  end

  #
  # Multiply the array by itself `n` times.
  #
  def **(n)
    super.to_a
  end

end


