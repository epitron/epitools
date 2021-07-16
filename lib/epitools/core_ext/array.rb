
class Array

  #
  # Better names
  #
  alias_method :lpush, :unshift
  alias_method :lpop,  :shift
  alias_method :uniq_by, :uniq

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
  # see: Enumerable#rzip
  #
  def rzip(other)
    super.to_a
    # reverse_each.zip(other.reverse_each).reverse_each.to_a
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
  # Transpose an array that could have rows of uneven length
  #
  def transpose_with_padding
    max_width = map(&:size).max
    map { |row| row.rpad(max_width) }.transpose
  end

  #
  # Remove instances of "element" from the end of the array (using `Array#pop`)
  #
  def rtrim!(element=nil)
    pop while last == element
    self
  end

  #
  # Like `rtrim!`, but returns a trimmed copy of the array
  #
  def rtrim(element=nil)
    dup.rtrim!(element)
  end

  ####################################################################
  # Pseudo-matrix methods
  ####################################################################

  def rows
    self
  end

  def columns
    cols = transpose_with_padding
    cols.each &:rtrim!
    cols
  end
  alias_method :cols, :columns

  #
  # Return row n of a 2D array
  #
  def row(n)
    rows[n]
  end

  #
  # Return column n of a 2D array
  #
  def column(n)
    columns[n]&.rtrim!
  end
  alias_method :col, :column

  #
  # Create a 2D matrix out of arrays
  #
  def self.matrix(height, width, initial_value=nil)
    if block_given?
      height.times.map do |row|
        width.times.map do |col|
          yield(row, col)
        end
      end
    else
      height.times.map do
        [initial_value] * width
      end
    end
  end

  alias_class_method :rect, :matrix
  alias_class_method :of_arrays, :matrix


  ####################################################################

  #
  # Extend the array the target_width by adding nils to the end (right side)
  #
  def rpad!(target_width)
    if target_width > size and target_width > 0
      self[target_width-1] = nil
    end
    self
  end

  #
  # Return a copy of this array which has been extended to target_width by adding nils to the end (right side)
  #
  def rpad(target_width)
    dup.rpad!(target_width)
  end

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
  # Convert an Array that contanis Hashes to a new Array that contains OpenStructs
  #
  def to_ostruct
    map do |e|
      e.respond_to?(:to_ostruct) ? e.to_ostruct : e
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
  def histogram(n_buckets=10, **options)

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

  module ToCSV
    #
    # Convert this enumerable into a CSV string (nb: enumerable must contain either all Hashes or all Arrays)
    #
    def to_csv(delimiter=",")
      types = count_by(&:class)

      unless types.size == 1 and (types[Array] > 0 or types[Hash] > 0)
        raise "Error: this array must contain nothing but arrays, or nothing but hashes (actually contains: #{types.inspect})"
      end

      options = {}
      options[:col_sep] = delimiter
      options[:headers] = flat_map(&:keys).uniq if types[Hash] > 0

      CSV.generate(nil, **options) do |csv|
        each { |obj| csv << obj }
      end
    end

    #
    # Like #to_csv, but with tab-separated CSV fields
    #
    def to_tsv
      to_csv("\t")
    end
  end

  prepend ToCSV # dirty hack to stop the CSV module from clobbering the to_csv method
end
