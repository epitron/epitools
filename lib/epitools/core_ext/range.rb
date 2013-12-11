class Range

  #
  # Pick a random number from the range.
  #
  def rand
    Kernel.rand(self)
  end

  #
  # The middle element of this range.
  #
  def middle
    (min + max) / 2
  end
  alias_method :mid, :middle

  def overlaps?(other)
    splice(other)[1] != nil
  end

  def splice(other)
    # 
    # Case 1:
    #      -----      => ---
    #         -----
    # Case 2:
    #         -----   =>    --
    #      -----
    # Case 3:         => self
    #      -----
    #             -----
    # Case 4:
    #      -----
    #      -----
    #

    a, b = (self <= other) ? [self, other] : [other, self]



    [a.min...b.min, b.min...a.max, a.max..b.max]
  end


  #
  # True when:
  #   self: ----
  #  other:      -----
  #           *or*
  #   self: ----------
  #  other:      -----
  #           *or*
  #   self: -----
  #  other: ----------
  #           *or*
  #   self: ------
  #   other:    ------
  #
  def <(other)
    (self.min < other.min and self.max <= other.max) or
    (self.min <= other.min and self.max < other.max)
  end

  #
  # True when:
  #   self:      -----
  #  other: ----
  #           *or*
  #   self:      -----
  #  other: ----------
  #           *or*
  #   self: ----------
  #  other: -----
  #           *or*
  #   self:     ------
  #   other: ------
  #
  def >(other)
    other < self
    #self.min > other.min and self.max <= other.max
  end

  def contains?(other)
    self.min < other.min and self.max > other.max
  end

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


class RangeSet

  def initialize(*ranges)
    @ranges = ranges.flatten
  end

  #
  # Minimize the set of ranges by analyzing the range overlap
  #
  def coalesce

  end

end