#
# A stable iterator class.
# (You can reorder/remove elements in the container without affecting iteration.)
#
# For example, to reverse all the elements in a list: 
#   >> i = Iter.new(1..10)
#   >> i.each_cons(2) { |a,b| b.move_before(a) }
#   >> i.to_a    #=> [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]  
#
class Iter

  attr_accessor :container

  def initialize(vals)
    @container = vals.map{|val| Elem.new(self, val)}
  end
  
  def self.from_elems(elems)
    new([]).tap { |i| i.container = elems }
  end

  def ==(other)
    case other
    when Iter
      @container == other.container
    when Array
      @container == other
    end
  end
  
  def each
    @container.each do |elem|
      yield elem
    end
  end
  
  def each_cons(num=1)
    @container.each_cons(num) do |(*elems)|
      yield *elems 
    end
  end
  
  alias_method :iterate,    :each_cons
  alias_method :every,      :each_cons

  def to_a
    @container.map(&:val)
  end

  def method_missing(name, *args)
    result = @container.send(name, *args)
    case result
    when Array
      Iter.from_elems result
    else
      result
    end
  end
  
  class Elem < BasicObject
  
    attr_accessor :val
    
    def initialize(iter, val)
      @iter = iter
      @val  = val.elem? ? val.value : val 
    end
    
    def elem?
      true
    end
    
    def ==(other)
      self.eql?(other)
    end
    
    def container
      @iter.container
    end
    
    def current
      self
    end
    
    def next
      p = pos+1
      if p >= container.size
        nil
      else
        container[p]
      end
    end
    
    def prev
      p = pos-1
      if p < 0
        nil
      else
        container[p]
      end
    end
    
    def remove
      container.delete_at(pos)
    end
    alias_method :delete, :remove
    
    def replace_with(replacement)
      container[pos] = Elem.new(@iter, replacement)
    end
    
    def pos
      container.index(self)
    end
    
    def move_before(other)
      remove
      container.insert(other.pos, self) # insert at pos and shift everything over
    end
    
    def move_after(other)
      remove
      container.insert(other.pos+1, self) # insert after pos
    end
    
    def move_first
      remove
      container.insert(0, self) # insert at beginning
    end
    alias_method :move_start, :move_first
    
    def move_last
      remove
      container.insert(-1, self) # insert at end
    end
    alias_method :move_end, :move_last
    
    def value
      @val
    end
    
    def method_missing(name, *args)
      @val.send(name, *args)
    end
    
    def inspect
      "<Elem: #{@val.inspect}>"
    end
  end
  
end

