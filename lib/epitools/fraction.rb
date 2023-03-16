#
# A fraction! (Like a Rational, but ... uh ... in pure Ruby!)
#
# Can be compared, added, multiplied, simplified, "percent"ed, "to_f"ed, and printed/inspected.
#
class Fraction

  attr_accessor :first, :last

  alias_method :top, :first
  alias_method :bottom, :last

  alias_method :numerator, :first
  alias_method :denominator, :last

  #
  # `first` is the top part of the fraction, `last` is the bottom (eg: `first/last`)
  #
  def initialize(first, last=1)
    @first = first
    @last = last
  end

  def self.[](*args)
    new(*args)
  end

  include Comparable

  def <=>(other)
    to_f <=> other.to_f
  end

  #
  # Returns a string representation: "a/b"
  #
  def to_s
    "#{@first}/#{@last}"
  end
  alias_method :fraction, :to_s

  #
  # Returns the fraction as a float. (eg: Fraction[1,2].to_f == 0.5)
  #
  def to_f
    if @last == 0
      raise ZeroDivisionError
    else
      @first.to_f / @last
    end
  end

  #
  # Returns a string representing the number in percent
  #
  def percent
    "%0.1f%%" % (to_f * 100)
  end
  alias_method :to_percent, :percent

  #
  # "#<Fraction: 1/2>"
  #
  def inspect
    "#<Fraction: #{to_s}>"
  end

  #
  # Adds together the tops and bottoms of the fractions.
  #
  # Example: For the fractions `a/c` and `b/d`, returns `a+b/c+d`
  #
  def +(r)
    case r
    when Integer
      self + Fraction[r]
    when Fraction
      Fraction[ r.last*first + r.first*last, r.last*last ]
    else
      raise TypeError.new("Sorry, I can't add a Fraction and a #{r.class}. :(")
    end
  end

  #
  # Multiply the fractions
  #
  def *(v)
    case v
    when Integer
      Fraction[ v*first, v*last ]
    when Fraction
      Fraction[ v.first*first, v.last*last ]
    else
      raise TypeError.new("I don't know how to multiply a Fraction and a #{v.class}. Sorry. :(")
    end
  end

  def simplify
    require 'prime'

    # factor the numerator and denominator into hashes of { factor => exponent } pairs
    n_fact, d_fact = [numerator, denominator].map { |n| Prime.prime_division(n).to_h }

    # cancel out common factors by subtracting exponents
    d_fact.each do |v, d_exp|
      if n_exp = n_fact[v]
        if n_exp < d_exp
          d_fact[v] = d_exp - n_exp
          n_fact[v] = 0
        else
          n_fact[v] = n_exp - d_exp # <= if n_exp == d_exp, this is 0, which covers the 3rd case
          d_fact[v] = 0
        end
      end
    end

    # multiply the simplified factors back into full numbers
    simp_n, simp_d = [n_fact, d_fact].map { |h| h.map{ |n, exp| n ** exp }.reduce(:*) }

    Fraction[simp_n, simp_d]
  end

end

#####################################################################################
#
# Fraction(a,b) is a wrapper for Fraction[a,b]
#
def Fraction(*args)
  Fraction.new(*args)
end
