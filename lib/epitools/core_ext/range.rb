class Range

  #
  # The actual last value in the range (eg: `(1...10).actual_last == 9`)
  #
  def actual_last
    exclude_end? ? last - 1 : last
  end

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
  # Return a new range which is the union of the two ranges (even if the two ranges don't overlap)
  #
  def |(other)
    vals = [
      first,
      other.first,
      actual_last,
      other.actual_last
    ].sort

    (vals.first..vals.last)
  end

  #
  # Merge this range with another (if the two ranges overlap, then it returns an array containing a single merged range; if the two ranges are disjoint, an array with the two ranges is returned)
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
    self.first <= other.actual_last and other.first <= self.actual_last
  end

  #
  # Takes an array of ranges, and returns a new array where all overlapping ranges are combined into a single range
  #
  def self.optimize(ranges)
    ranges = ranges.sort_by(&:first)

    result = [ranges.first]

    ranges[1..-1].each do |elem|
      if result[-1].overlaps?(elem)
        result[-1] = (result[-1] | elem)
      else
        result << elem
      end
    end

    result
  end

end
