class Numeric

  def integer?; true; end

  def truthy?; self > 0; end

  def commatize  
    to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
  end

  #
  # Clamp the number to a specific range
  #
  # Examples:
  #    234234234523.clamp(0..100)   #=> 100
  #    12.clamp(0..100)             #=> 12  
  #    -38817112.clamp(0..100)      #=> 0
  #
  def clamp(range)
    if self < range.first
      range.first
    elsif self >= range.last 
      if range.exclude_end?
        range.last - 1
      else
        range.last
      end
    else
      self
    end
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
      (0...self).to_a
    end
  end

  [:cos,
   :sin,
   :tan,
   :acos,
   :asin,
   :atan,
   :cosh,
   :sinh,
   :tanh,
   :acosh,
   :asinh,
   :atanh,
   :exp,
   :log2,
   :log10,
   :sqrt,
   :cbrt,
   :frexp,
   :erf,
   :erfc,
   :gamma,
   :lgamma
  ].each do |meth|

    class_eval %{
      def #{meth}
        Math.#{meth}(self)
      end
    }

  end

  # Math.log is different in 1.8
  if RUBY_VERSION["1.8"]
    def log(n); Math.log(self) / Math.log(n); end
  else
    def log(n); Math.log(self, n); end
  end


  BYTE_SIZE_TABLE = {
    # power    # units
    0          => "",
    1          => "KB",
    2          => "MB",
    3          => "GB",
    4          => "TB",
    5          => "PB",
    6          => "EB",
    7          => "ZB",
    8          => "YB",
  }

  def human_bytes(decimals=0)
    power = self.log(1024).floor
    base  = 1024.0 ** power
    units = BYTE_SIZE_TABLE[power]
    "#{(self / base).round(decimals)}#{units}"
  end

  alias_method :human_size, :human_bytes

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

  #
  # Factorial (iterated style)
  #
  def fact
    total = 1
    self.downto(2) { |x| total *= x }
    total
  end
  alias_method :factorial, :fact

  #
  # Fibonacci (recursive style)
  #
  def fib
    self < 2 ? self : (self-1).fib + (self-2).fib
  end
  alias_method :fibonacci, :fib

  #
  # Convert seconds to hours:minutes:seconds (hours is dropped if it's zero)
  #
  def to_hms
    seconds = self

    days, seconds    = seconds.divmod(86400)
    hours, seconds   = seconds.divmod(3600)
    minutes, seconds = seconds.divmod(60)

    result = "%0.2d:%0.2d" % [minutes,seconds]
    result = ("%0.2d:" % hours) + result   if hours > 0 or days > 0
    result = ("%0.2d:" % days) + result    if days > 0

    result
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
