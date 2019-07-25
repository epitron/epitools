#require 'epitools'

#
# Allow numbers to be converted into words, or exprssed more easily with words.
#
# Examples:
#     >> 1.thousand
#     => 1_000

#     >> 1.27.million.billion
#     => 1_270_000_000_000_000
#
#     >> 12873218731.to_words
#     => "twelve billion, eight-hundred and seventy-three million, two-hundred and eighteen thousand, seven-hundred and thirty-one"
#
# Works on numbers up to a googol!
#
class Numeric

  # < 20
  NAMES_SMALL = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"
  ]

  # 20-90
  NAMES_MEDIUM = [
    "twenty", "thirty", "fourty", "fifty", "sixty", "seventy", "eighty", "ninety"
  ]

  # >= 100
  NAMES_LARGE = [
    "thousand", "million", "billion", "trillion", "quadrillion", "quintillion", "sextillion", "septillion", "octillion", "nonillion", "decillion", "undecillion", "duodecillion", "tredecillion", "quattuordecillion", "quindecillion", "sexdecillion", "septendecillion", "octodecillion", "novemdecillion", "vigintillion", "unvigintillion", "duovigintillion", "trevigintillion", "quattuorvigintillion", "quinvigintillion", "sexvigintillion", "septenvigintillion", "octovigintillion", "novemvigintillion", "trigintillion", "untrigintillion", "duotrigintillion"
  ]

  #
  # Convert this number to words (eg: 69 => 'sixty-nine').
  # Works with numbers up to a googol (10^100).
  #
  def to_words
    if is_a? Integer
      num = self
    else
      num = self.to_i
    end

    if (n = num.to_s.size) > 102
      return "more than a googol! (#{n} digits)"
    end

    whole_thing = []

    triplets = num.commatize.split(',')
    num_triplets = triplets.size

    triplets.each_with_index do |triplet, i|
      next if triplet.to_i == 0

      result = []

      tens, hunds = nil, nil

      digits = triplet.chars.to_a

      raise "Error: Not a triplet: #{triplet}" if digits.size > 3 or digits.size < 1

      if digits.size == 3
        digit = digits.shift.to_i
        hunds = NAMES_SMALL[digit] + "-hundred" if digit > 0
        digits.shift if digits.first == '0'
      end

      if digits.size == 2
        n = digits.join('').to_i

        if n > 0 and n < 20
          tens = NAMES_SMALL[n]
        elsif n > 0
          tens = NAMES_MEDIUM[digits.shift.to_i - 2]
          if digits.first != '0'
            tens += "-" + NAMES_SMALL[digits.shift.to_i]
          else
            digits.shift
          end
        end
      end

      if digits.size == 1
        n = digits.join('').to_i
        tens = NAMES_SMALL[n] if n > 0
      end

      if hunds
        if tens
          result << "#{hunds} and #{tens}"
        else
          result << hunds
        end
      else
        result << tens if tens
      end

      magnitude = (num_triplets - i)
      result << NAMES_LARGE[magnitude-2] if magnitude > 1

      whole_thing << result.join(' ') if result.any?
    end

    whole_thing.join ', '
  end

  #
  # Define the .million, .thousand, .hundred, etc. methods.
  #
  NAMES_LARGE.each_with_index do |name, magnitude|
    define_method name do
      pow       = (magnitude+1) * 3
      factor    = 10**pow

      if is_a?(Float)
        (BigDecimal(to_s) * factor).to_i
      else
        self * factor
      end
    end
  end

end


