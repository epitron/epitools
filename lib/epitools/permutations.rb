require 'epitools'

class Array

  alias_method :mult, :"*"

  #
  # Overloaded * operator.
  #
  # Original behaviour:
  #   array * number == <number> copies of array
  # Extra behaviour:
  #   array * array = Cartesian product of the two arrays
  #
  def *(other)
    if other.is_a? Array
      # cross-product
      result = []
      (0...self.size).each do |a|
        (0...other.size).each do |b|
          result << [self[a], other[b]]
        end
      end
      result
    else
      send(:mult, other)
    end
  end

  #
  # Multiply the array by itself 'exponent'-times.
  #
  def **(exponent)
    ([self] * exponent).foldl(:*)
  end

  def all_pairs(reflexive=false)
    (0...size).each do |a|
      start = reflexive ? a : a+1
      (start...size).each do |b|
        yield self[a], self[b]
      end
    end
  end

  enumerable :all_pairs

end


#
# Returns all the `size`-sized selections of the elements from an array.
#
# I can't remember why I wrote it like this, but the array you want to
# permute is passed in as a block. For example:
#
#   >> perms(1) { [1,2,3,4] }
#   => [[1], [2], [3], [4]]
#   >> perms(2) { [1,2,3,4] }
#   => [[1, 1], [1, 2], [1, 3], [1, 4], [2, 1], [2, 2], [2, 3], [2, 4],
#       [3, 1], [3, 2], [3, 3], [3, 4], [4, 1], [4, 2], [4, 3], [4, 4]]
#
# The block also gets passed a parameter: the depth of the recursion.
# I can't remember why I did that either! :D
#
def perms(size, n=0, stack=[], &block)
  ps = yield(n)
  results = []
  if n >= size
    results << stack
  else
    ps.each do |p|
      results += perms(size, n+1, stack + [p], &block)
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
