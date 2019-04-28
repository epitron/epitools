
Number = Numeric # "obj.is_a? Number" just sounds better.

class Numeric

  #
  # Convert this number to a string, adding commas between each group of 3 digits.
  #
  # (The "char" argument is optional, and specifies what character to use in between
  #  each group of numbers.)
  #
  def commatize(char=",")
    str = self.is_a?(BigDecimal) ? to_s("F") : to_s

    int, frac = str.split(".")
    int = int.gsub /(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/, "\\1#{char}\\2"

    frac ? "#{int}.#{frac}" : int
  end

  #
  # Convert this number to a string, adding underscores between each group of 3 digits.
  #
  def underscorize
    commatize("_")
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


  def ln
    Math.log(self)
  end


  #
  # Combinations: compute "n choose r" (self.choose(r))
  #
  # This represents number of ways to pick "r" items from a collection of "self"
  # items (where the order of the items doesn't matter, and items can't be repeated.)
  #
  # eg: 49.choose(6) is how many ways can we pick 6 lottery numbers from a set of 49.
  #
  # Formula: n! / (r! * (n-r)!) == n * n-1 * ... * n-r / r * r-1 * ... * 2
  #
  def choose(r)
    (self-r+1..self).reduce(:*) / (2..r).reduce(:*)
  end
  alias_method :combinations, :choose

  #
  # Permutations: compute "n P r"
  #
  # This represents number of ways to pick "r" items from a collection of "self"
  # items (where the order of the items DOES matter, and items can't be repeated.)
  #
  # eg: 23.perm(3) is how many ways 23 people can win 1st, 2nd and 3rd place in a race.
  #
  # Formula: n! / (n - r)!
  #
  def perms(r)
    (self-r+1..self).reduce(:*)
  end
  alias_method :permutations, :perms

  #
  # Multiply self by n, returning the integer product and the floating point remainder.
  #
  def mulmod(n)
    prod    = self * n
    intprod = prod.to_i

    [intprod, prod % intprod]
  end

  # Math.log is different in 1.8
  if RUBY_VERSION["1.8"]

    def log(n=nil)
      if n
        Math.log(self) / Math.log(n)
      else
        Math.log(self)
      end
    end

  else

    def log(n=nil)
      if n
        Math.log(self, n)
      else
        Math.log(self)
      end
    end

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

  #
  # Convert seconds to hours:minutes:seconds (hours is dropped if it's zero)
  #
  def to_hms
    seconds = self

    days, seconds    = seconds.divmod(86400)
    hours, seconds   = seconds.divmod(3600)
    minutes, seconds = seconds.divmod(60)
    seconds, frac    = seconds.divmod(1)

    result = "%0.2d:%0.2d" % [minutes,seconds]
    result = ("%0.2d:" % hours) + result   if hours > 0 or days > 0
    result = ("%0.2d:" % days)  + result   if days > 0
    result += ("." + frac.round(2).to_s.split(".").last) if frac > 0

    result
  end

  def to_hms_in_words
    seconds = self

    days, seconds    = seconds.divmod(86400)
    hours, seconds   = seconds.divmod(3600)
    minutes, seconds = seconds.divmod(60)
    seconds, frac    = seconds.divmod(1)

    result = "#{seconds} sec"
    result = "#{minutes} min, " + result if minutes > 0
    result = "#{"hour".amount(hours)}, " + result if hours > 0 or days > 0
    result = "#{"day".amount(days)}, "   + result if days > 0
    # result += ("." + frac.round(2).to_s.split(".").last) if frac > 0

    result
  end

end


class Integer

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
    # TODO: Why does this go into an infinite loop in 1.8.7?
    ("%b" % self).chars.to_a.reverse.map(&:to_i)
  end
  alias_method :bits, :to_bits

  #
  # Cached constants for encoding numbers into bases up to 64
  #
  BASE_DIGITS       = [*'0'..'9', *'A'..'Z', *'a'..'z', '_', '-']
  SMALL_POWERS_OF_2 = {2=>1, 4=>2, 8=>3, 16=>4, 32=>5, 64=>6}

  #
  # Convert a number into a string representation (encoded in a base <= 64).
  #
  # The number is represented usiing the characters: 0..9, A..Z, a..z, _, -
  #
  # (Setting base to 64 results in the encoding scheme that YouTube and url shorteners
  # use for their ID strings, eg: http://www.youtube.com/watch?v=dQw4w9WgXcQ)
  #
  def to_base(base=10)
    raise "Error: Can't handle bases greater than 64" if base > 64

    n        = self
    digits   = []
    alphabet = BASE_DIGITS[0...base]

    if bits = SMALL_POWERS_OF_2[base]
      # a slightly accelerated version for powers of 2
      mask   = (2**bits)-1

      loop do
        digits << (n & mask)
        n = n >> bits

        break if n == 0
      end
    else
      # generic base conversion
      loop do
        n, digit = n.divmod(base)
        digits << digit

        break if n == 0
      end
    end

    digits.reverse.map { |d| alphabet[d] }.join
  end

  def to_base62
    to_base(62)
  end

  #
  # Am I a prime number?
  #
  def prime?
    Prime.prime? self
  end

  #
  # Return a specified number of primes (optionally starting at the argument)
  #
  def primes(starting_at=2)
    result  = []
    current = starting_at

    loop do
      if current.prime?
        result << current
        return result if result.size >= self
      end
      current += 1
    end
  end

  #
  # Returns the all the prime factors of a number.
  #
  def factors
    Prime # autoload the prime module
    prime_division.map { |n,count| [n]*count }.flatten
  end

  #
  # Factorial
  #
  def fact
    if self < 0
      -(1..-self).reduce(:*)
    elsif self == 0
      1
    else
      (1..self).reduce(:*)
    end
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
  # Flip all bits except the sign bit.
  #
  # NOTE: This method should only be used with unsigned integers; if you use it with a signed
  # integer, it will only flip the non-sign bits (I dunno if that's useful for anything; nothing comes to mind.)
  #
  def invert
    to_s(2).tr("01","10").to_i(2)
  end

end

#
# Adds integer silcing (returning the bits) and raw-bytes
#
# (This is necessary because [] is defined directly on the classes, and a mixin
#  module will still be overridden by Big/Fixnum's native [] method.)
#
(RUBY_VERSION >= "2.4" ? [Integer] : [Bignum, Fixnum]).each do |klass|
  klass.class_eval do

    alias_method :bit, :"[]"

    #
    # Slice the bits of an integer by passing a range (eg: 1217389172842[0..5] #=> [0, 1, 0, 1, 0, 1])
    #
    def [](arg)
      case arg
      when Integer
        bit(arg)
      when Range
        bits[arg]
      end
    end

    #
    # Convert the integer into its sequence of bytes (little endian format: lowest-order-byte first)
    #
    # TODO: This could be made much more efficient!
    #
    def bytes
      nbytes = (bit_length / 8.0).ceil

      (0..nbytes).map do |current_byte|
        (self >> (8 * current_byte)) & 0xFF
      end
    end

    def big_endian_bytes
      bytes.reverse
    end
  end
end


class Float

  #
  # Convert the float to a rounded percentage string (eg: "42%").
  # Its argument lets you specify how many decimals to display
  #
  # eg:
  #    > 0.32786243.percent # => "33%"
  #    > 0.32786243.percent(2) # => "32.79%"
  #
  def percent(decimals=0)
    "%0.#{decimals}f%%" % (self * 100)
  end

end


class Prime

  #
  # Return an array of prime numbers within the specified range
  #
  def [](range)
    ubound    = range.end
    lbound    = range.begin
    ubound   -= 1 if range.exclude_end?
    generator = each(ubound)
    n         = nil

    loop do
      break if (n = generator.succ) >= lbound
    end

    [n, *generator.to_a]
  end

end

#
# Return an infinite enumerable of primes
#
def primes
  Prime.instance
end
