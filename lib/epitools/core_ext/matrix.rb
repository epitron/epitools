require 'matrix'

#
# Matrix extensions
#
class Matrix

  alias_class_method :zeros, :zero
  alias_class_method :zeroes, :zero

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
  # Allow mathematical operations (*, /, +, -) with a regular number on the right side.
  #
  # eg: Matrix.zero(3) + 5
  #
  %w[* / + -].each do |op|
    class_eval %{
      def #{op}(other)
        case other
        when Fixnum, Float
          map { |e| e #{op} other }
        else
          super(other)
        end
      end
    }
  end

  public :[]=

end
