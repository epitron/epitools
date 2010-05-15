
class Ratio

  include Comparable

  def <=>(other)
    to_f <=> other.to_f
  end

  attr_accessor :first, :last

  def self.[](*args)
    new(*args)
  end

  def initialize(first, last=1)
    @first = first
    @last = last
  end

  def to_s
    "#{@first}/#{@last}"
  end
  alias_method :ratio, :to_s

  def to_f
    if @last == 0
      0.0
    else
      @first.to_f / @last
    end
  end

  def percent
    "%0.1f%" % (to_f * 100)
  end
  alias_method :to_percent, :percent

  def inspect
    "#<Ratio: #{to_s}>"
  end

  def +(other)
    Ratio.new( first+other.first, last+other.last)
  end

end

