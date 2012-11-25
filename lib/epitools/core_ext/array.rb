
class Array

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
  #   odd = nums                              # "nums" now only contains odd numbers
  #
  def remove_if(&block)
    removed = []

    delete_if do |x|
      if block.call(x)
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
    # That's a lotta reverses!
    reverse.zip(other.reverse).reverse
  end

  #
  # Pick the middle element.
  #
  def middle
    self[(size-1) / 2]
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
  unless defined? shuffle
    def shuffle
      sort_by{rand}
    end
  end

  #
  # Pick (a) random element(s).
  #
  unless defined? sample
    def sample(n=1)
      if n == 1
        self[rand(size)]
      else
        shuffle[0...n]
      end
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
  def to_h
    if self.first.is_a? Array
      Hash[self]
    else
      Hash[*self]
    end
  end

end


