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

  #
  # Merge two ranges
  #
  def merge(other)
    if self.overlaps?(other)
      [self | other]
    else
      [self, other]
    end
  end

  #
  # Test if this range overlaps the other
  #
  def overlaps?(other)
    # overlap == start < finish' AND start' < finish
    self.first <= other.last and other.first <= self.last
  end

end
