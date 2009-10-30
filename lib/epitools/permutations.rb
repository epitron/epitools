
class Array
  
  def sum
    inject(0) { |total,n| total + n }
  end
  
  def average
    sum / size.to_f
  end

  alias_method :"original_*_for_cartesian_*", :*
  def *(other)
    case other
      when Integer
        send(:"original_*_for_cartesian_*", other)
      when Array
        # cross-product
        result = []
        (0...self.size).each do |a|
          (0...other.size).each do |b|
            result << [self[a], other[b]]
          end
        end
        result        
    end
  end
  
  def **(exponent)
    ([self] * exponent).foldl(:*)
  end
  
end


module Enumerable

  def foldl(operation)
    result = nil

    each_with_index do |e,i|
      if i == 0
        result = e 
        next
      end
      
      result = result.send(operation, e)      
    end
    
    result
  end

end


def perms(total, n=0, stack=[], &block)
  ps = yield(n)
  results = []
  if n >= total
    results << stack
  else  
    ps.each do |p|
      results += perms(total, n+1, stack + [p], &block)
    end
  end
  results
end
  

if $0 == __FILE__
  puts "-------------- foldl ---"
  p [:sum, [1,1,1].foldl(:+)]
  p ["[[1,2],[3]].foldl(:+)", [[1,2],[3]].foldl(:+)]
  p [[0,1],[0,1]].foldl(:*)

  puts "-------------- cartesian product ---"
  p ["[0,1]*[2,3]",[0,1]*[2,3]]

  puts "-------------- cartesian exponent ---"
  p [0,1]**3
end
