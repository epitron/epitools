require 'epitools/minimal'

class Date

  def self.find(direction=:backward, &block)
    Date.today.find(direction, &block)
  end
  alias_class_method :search, :find

  def self.find(direction=:backward, &block)
    Date.today.find(direction, &block)
  end
  alias_class_method :search, :find

  def self.find_bidirectional(&block)
    Date.today.find_bidirectional(&block)
  end
  alias_class_method :find_both, :find_bidirectional
  alias_class_method :search_both, :find_bidirectional
  alias_class_method :search_bidirectional, :find_bidirectional


  #
  # Returns an enumerator which searches through the calendar a day at a time, returning every date that match the block.
  #
  # Examples:
  #   >> Date.find(:forward) { year % 42 == 0 }
  #   >> Date.find(:backward) { month == 1 }
  #   >> Date.parse("1900-01-01").find_bidirectional { wednesday? }
  #   >> Date.today.find_forward { wednesday? and day == 4 }.take(10)
  #
  # (Note: the block doesn't need a parameter; every method you call is sent directly to the date object that's being evaluated)
  #
  def find(direction=:backward, &block)
    raise ArgumentError.new("This method requires a block") unless block_given?
    Enumerator.new do |y|
      p = self

      loop do
        y << p if p.instance_eval(&block)

        case direction
        when :forward, :forwards
          p = p.next_day
        when :backward, :backwards
          p = p.prev_day
        else
          raise "Error: Unknown date search direction #{direction.inspect}"
        end
      end
    end
  end

  alias_method :search, :find


  def find_forwards(&block)
    find(:forwards, &block)
  end

  def find_backwards(&block)
    find(:backwards, &block)
  end

  def find_bidirectional(&block)
    f = find(:forward, &block)
    b = find(:backward, &block)

    Enumerator.new do |y|
      loop do
        y << b.next
        y << f.next
      end
    end
  end

  alias_method :find_backward, :find_backwards
  alias_method :find_forward,  :find_forwards

  alias_method :find_both,            :find_bidirectional
  alias_method :search_both,          :find_bidirectional
  alias_method :search_bidirectional, :find_bidirectional

end
