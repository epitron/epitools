class Range

  #
  # Pick a random number from the range.
  #
  def rand
    Kernel.rand(self)
  end

  #
  # The number in the middle of this range.
  #
  def mid
    (min + max) / 2
  end
  alias_method :middle, :mid

  #
  # Return a new range which is the intersection of the two ranges
  #
  def &(other)
    mins, maxes = minmax.zip(other.minmax)

    (mins.max..maxes.min)
  end
  
  #
  # Return a new range which is the union of the two ranges
  #
  def |(other)
    mins, maxes = minmax.zip(other.minmax)

    (mins.min..maxes.max)
  end
  
end
