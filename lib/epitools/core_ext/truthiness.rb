
class Object
  
  #
  # Default "integer?" behaviour.
  #
  def integer?; false; end
   
  #
  # Default "float?" behaviour.
  #
  def float?; false; end

  #
  # Default "number?" behaviour.
  #
  def number?; false; end

  #
  # `truthy?` means `not blank?`
  #
  def truthy?
    if respond_to? :blank?
      not blank?
    else
      not nil?
    end
  end
  
end


class TrueClass

  def truthy?; true; end

end


class FalseClass

  def truthy?; false; end

end


class Numeric

  def truthy?; self > 0; end

  def number?; true; end

end  


class Integer

  #
  # 'true' if the integer is 0
  #
  def blank?; self == 0; end

  def integer?; true; end

end


class Float

  #
  # 'true' if the float is 0.0
  #
  def blank?; self == 0.0; end

  def float?; true; end

end


class NilClass

  #
  # Always 'true'; nil is considered blank.
  #
  def blank?; true; end

end


class Symbol

  #
  # Symbols are never blank.
  #
  def blank?; false; end

end


class String
  
  #
  # Could this string be cast to an integer?
  #
  def integer?
    !!strip.match(/^-?\d+$/)
  end

  #
  # Could this string be cast to an float?
  #
  def float?
    !!strip.match(/^-?\d+\.\d+$/)
  end

  #
  # Could this string be cast to an number?
  #
  def number?
    !!strip.match(/^-?\d\.?\d*$/)
  end

  #
  # 'true' if the string's length is 0 (after whitespace has been stripped from the ends)
  #
  def blank?
    strip.size == 0
  end

  #
  # Is there anything in the string? (ignoring whitespace/newlines)
  #
  def any?
    not blank?
  end
  alias_method :present?, :any?

  #
  # Does this string contain something that means roughly "true"?
  #
  def truthy?
    case strip.downcase
    when "1", "true", "yes", "on", "enabled", "affirmative"
      true
    else
      false
    end
  end

end