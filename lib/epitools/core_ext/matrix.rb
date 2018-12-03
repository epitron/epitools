#
# TODO: Reimplement Matrix so it's not so awful, and give it a new name (like Grid).
#       (Goal: To be as nice as numpy)
#
# Features:
# * Better constructors
# * Pretty-printer support
# * .rows, .cols, .each_{row,col}, .neighbourhood
# * Vec class, Point class
#

require 'matrix'

#
# Matrix extensions
#
class Matrix

  alias_class_method :zeros, :zero
  alias_class_method :zeroes, :zero

  #
  # Build an array of 1's
  #
  def self.ones(*dims)
    build(*dims) { 1 }
  end

  #
  # Create a matrix of the specified size full of random numbers.
  #
  def self.random(*dims)
    build(*dims) { rand }
  end

  #
  # The size of the matrix, returned as `[rows, columns]`.
  #
  def size
    [row_size, column_size]
  end

  #
  # Iterate over rows (takes a block or returns an Enumerator)
  #
  def each_row
    return to_enum(:each_row) unless block_given?

    (0...row_count).each do |num|
      yield row(num)
    end
  end

  #
  # Print the matrix to the STDOUT.
  #
  def print(header=true, separator=" ")
    max_width = map {|num| num.to_s.size }.max

    case first
    when Integer
      justify = :rjust
    when Float
      justify = :ljust
    else
      raise "Unknown matrix element type: #{first.class}"
    end

    # print it!
    puts "#{size.join("x")} matrix:" if header

    rows.each do |row|
      puts "  " + row.map { |n| n.to_s.send(justify, max_width) }.join(separator)
    end

    puts
  end
  alias_method :draw, :print

  #
  # Overlay one matrix onto another
  #
  def blit!(submatrix, top, left)
    submatrix.each_row.with_index do |row, y|
      row.each.with_index do |elem, x|
        self[top+y,left+x] = elem
      end
    end
  end
  alias_method :overlay!, :blit!

  #
  # Allow mathematical operations (*, /, +, -) with a scalar (integer or float) on the right side.
  #
  # eg: Matrix.zero(3) + 5
  #
  %i[* / + -].each do |op|
    class_eval %{
      def #{op}(other)
        case other
        when Numeric
          map { |e| e #{op} other }
        else
          super(other)
        end
      end
    }
  end

  public :[]=

end
