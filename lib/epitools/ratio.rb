#
# The ratio between two numbers (eg: 2:1, 3:4)
#
# Can be compared, added, "percent"ed, "to_f"ed, and displayed.
#
class Ratio

  include Comparable

  def <=>(other)
    to_f <=> other.to_f
  end

  attr_accessor :first, :last

  def self.[](*args)
    new(*args)
  end

  #
  # `first` is the top part of the ratio, `last` is the bottom (eg: `first/last`)
  #
  def initialize(first, last=1)
    @first = first
    @last = last
  end

  #
  # Returns a string representation: "a/b"
  #
  def to_s
    "#{@first}/#{@last}"
  end
  alias_method :ratio, :to_s

  #
  # Returns the ratio as a float. (eg: Ratio[1,2].to_f == 0.5)
  #
  def to_f
    if @last == 0
      0.0
    else
      @first.to_f / @last
    end
  end

  #
  # Returns a string representing the number in percent
  #
  def percent
    "%0.1f%" % (to_f * 100)
  end
  alias_method :to_percent, :percent

  #
  # "#<Ratio: 1/2>"
  #
  def inspect
    "#<Ratio: #{to_s}>"
  end

  #
  # Adds together the tops and bottoms of the ratios.
  #
  # Example: For the ratios `a/c` and `b/d`, returns `a+b/c+d`
  #
  def +(other)
    Ratio.new( first+other.first, last+other.last)
  end

end

#
# Function-style wrapper
#
def Ratio(*args)
  Ratio.new(*args)
end
