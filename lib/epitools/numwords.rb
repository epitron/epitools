require 'epitools/basetypes'
require 'bigdecimal'
require 'set'

class Numeric
  
  NAMES_SMALL = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"
  ]

  NAMES_MEDIUM = [
    "twenty", "thirty", "fourty", "fifty", "sixty", "seventy", "eighty", "ninety"
  ]

  NAMES_LARGE = [
    "thousand", "million", "billion", "trillion", "quadrillion", "quintillion", "sextillion", "septillion", "octillion", "nonillion", "decillion", "undecillion", "duodecillion", "tredecillion", "quattuordecillion", "quindecillion", "sexdecillion", "septendecillion", "octodecillion", "novemdecillion", "vigintillion", "unvigintillion", "duovigintillion", "trevigintillion", "quattuorvigintillion", "quinvigintillion", "sexvigintillion", "septenvigintillion", "octovigintillion", "novemvigintillion", "trigintillion", "untrigintillion", "duotrigintillion"
  ]
  
  NAMES_LARGE_LOOKUP = Set.new(NAMES_LARGE)

  
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
      result = []
      
      tens, hunds = nil, nil
      
      chars = triplet.chars.to_a
      
      raise "Error: Not a triplet: #{triplet}" if chars.size > 3 or chars.size < 1      
      
      if chars.size == 3
        n = chars.shift.to_i 
        hunds = NAMES_SMALL[n] + "-hundred" if n > 0 
        chars.shift if chars.first == '0'
      end
      
      if chars.size == 2 
        n = chars.join('').to_i
        
        if n > 0 and n < 20 
          tens = NAMES_SMALL[n] 
        elsif n > 0
          tens = NAMES_MEDIUM[chars.shift.to_i - 2]
          if chars.first != '0'
            tens += "-" + NAMES_SMALL[chars.shift.to_i]
          else
            chars.shift
          end
        end
      end
      
      if chars.size == 1
        n = chars.join('').to_i 
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
        
      whole_thing << result.join(' ')
    end
    
    whole_thing.join ', '
    
  end

  #
  # Gives all numbers ".thousand", ".million", up to ".duotrigintillion" methods.
  # eg: 10.million #=> 10_000_000
  #
  def method_missing(meth, &block)
    super
  rescue NoMethodError
    if NAMES_LARGE_LOOKUP.include? meth.to_s
      magnitude = NAMES_LARGE.index(meth.to_s) 
      pow       = (magnitude+1) * 3
      factor    = 10**pow
      
      if is_a?(Float) 
        (BigDecimal(to_s) * factor).to_i
      else
        self * factor
      end
    else
      raise NoMethodError.new(meth)
    end
  end
  
end


