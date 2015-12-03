
class Object
  
  #
  # Default "integer?" behaviour.
  #
  def integer?; false; end
   
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

class Integer
  def integer?; true; end
end

class TrueClass

  def truthy?; true; end

end


class FalseClass

  def truthy?; false; end

end


class Float

  #
  # 'true' if the float is 0.0
  #
  def blank?; self == 0.0; end

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
