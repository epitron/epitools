class Numeric

  def integer?; true; end

  def truthy?; self > 0; end

  def commatize  
    to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
  end

  #
  # Time methods
  #
  {
  
    'second'  => 1,
    'minute'  => 60,
    'hour'    => 60 * 60,
    'day'     => 60 * 60 * 24,
    'week'    => 60 * 60 * 24 * 7,
    'month'   => 60 * 60 * 24 * 30,
    'year'    => 60 * 60 * 24 * 365,
    
  }.each do |unit, scale|
    define_method(unit)     { self * scale }
    define_method(unit+'s') { self * scale }
  end
  
  def ago
    Time.now - self
  end
  
  def from_now
    Time.now + self
  end

  #
  # If `n.times` is like `each`, `n.things` is like `map`. Return 
  #  
  def things(&block)
    if block_given?
      Array.new(self, &block)
    else
      Array.new(self)
    end
  end

end


class Time

  #
  # Relative time, in words. (eg: "1 second ago", "2 weeks from now", etc.)
  #
  def in_words
    delta   = (Time.now-self).to_i
    a       = delta.abs
    
    amount  = case a
      when 0                  
        'just now'
      when 1                  
        '1 second'
      when 2..59              
        "second".amount(a) 
      when 1.minute...1.hour            
        "minute".amount(a/1.minute)
      when 1.hour...1.day           
        "hour".amount(a/1.hour)
      when 1.day...7.days
        "day".amount(a/1.day)
      when 1.week...1.month
        "week".amount(a/1.week)
      when 1.month...12.months
        "month".amount(a/1.month)
      else
        "year".amount(a/1.year)
    end
              
    if delta < 0
      amount += " from now"
    elsif delta > 0
      amount += " ago"
    end
    
    amount
  end
  
end



class Integer
  
  #
  # 'true' if the integer is 0
  #
  def blank?; self == 0; end

  #
  # Convert the number into a hexadecimal string representation.
  # (Identical to to_s(16), except that numbers < 16 will have a 0 in front of them.)
  #
  def to_hex
    "%0.2x" % self
  end
    
  #
  # Convert the number to an array of bits (least significant digit first, or little-endian).
  #
  def to_bits
    # TODO: Why does thos go into an infinite loop in 1.8.7?
    ("%b" % self).chars.to_a.reverse.map(&:to_i)
  end
  alias_method :bits, :to_bits
  
  #
  # Cached constants for base62 encoding
  #
  BASE62_DIGITS   = ['0'..'9', 'A'..'Z', 'a'..'z'].map(&:to_a).flatten 
  BASE62_BASE     = BASE62_DIGITS.size

  #
  # Convert a number to a string representation (in "base62" encoding).
  # 
  # Base62 encoding represents the number using the characters: 0..9, A..Z, a..z
  #
  # It's the same scheme that url shorteners and YouTube uses for their
  # ID strings. (eg: http://www.youtube.com/watch?v=dQw4w9WgXcQ)
  #
  def to_base62
    result = []
    remainder = self
    max_power = ( Math.log(self) / Math.log(BASE62_BASE) ).floor
    
    max_power.downto(0) do |power|
      divisor = BASE62_BASE**power
      #p [:div, divisor, :rem, remainder]      
      digit, remainder = remainder.divmod(divisor)
      result << digit
    end
    
    result << remainder if remainder > 0
    
    result.map{|digit| BASE62_DIGITS[digit]}.join ''
  end

  #
  # Returns the all the prime factors of a number.
  #
  def factors
    Prime # autoload the prime module
    prime_division.map { |n,count| [n]*count }.flatten 
  end
  
end


#
# Monkeypatch [] into Bignum and Fixnum using class_eval.
#
# (This is necessary because [] is defined directly on the classes, and a mixin
#  module will still be overridden by Big/Fixnum's native [] method.)
#
[Bignum, Fixnum].each do |klass|
  
  klass.class_eval do
    
    alias_method :bit, :"[]"
    
    #
    # Extends [] so that Integers can be sliced as if they were arrays.
    #
    def [](arg)
      case arg
      when Integer
        self.bit(arg)
      when Range
        self.bits[arg]
      end
    end
    
  end
  
end



