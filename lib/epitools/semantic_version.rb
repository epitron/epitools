class SemanticVersion

  include Comparable

  A_NEWER = 1
  B_NEWER = -1
  A_EQ_B  = 0

  attr_reader :val

  def initialize(val)
    @val = val
  end

  def self.compare(a,b)
    new(a) <=> new(b)
  end

  def <=>(other)
    version_a, version_b = val, other.val

    return A_EQ_B if version_a == version_b

    chars_a, chars_b = version_a.chars, version_b.chars

    while chars_a.size != 0 and chars_b.size != 0
      # logger.debug('starting loop comparing %s '
      #        'to %s', chars_a, chars_b)
      check_leading(chars_a, chars_b)

      if chars_a.first == '~' and chars_b.first == '~'
        chars_a.shift
        chars_b.shift
      elsif chars_a.first == '~'
        return B_NEWER
      elsif chars_b.first == '~'
        return A_NEWER
      end

      break if chars_a.size == 0 or chars_b.size == 0

      block_res = get_block_result(chars_a, chars_b)
      return block_res if block_res != A_EQ_B
    end

    if chars_a.size == chars_b.size
      # logger.debug('versions are equal')
      return A_EQ_B
    else
      # logger.debug('versions not equal')
      chars_a.size > chars_b.size ? A_NEWER : B_NEWER
    end
  end


private

  def check_leading(*char_lists)
    # logger.debug('_check_leading(%s)', char_lists)
    for char_list in char_lists
      while char_list.any? and not char_list[0] =~ /^\w/ and not char_list[0] == '~'
        char_list.shift
      end
      # logger.debug('updated list: %s', char_list)
    end
  end

  def get_block_result(chars_a, chars_b)
    # logger.debug('get_block_result(%s, %s)', chars_a, chars_b)
    first_is_digit   = chars_a.first =~ /^\d/
    pop_func         = first_is_digit ? :pop_digits : :pop_letters
    return_if_no_b   = first_is_digit ? A_NEWER : B_NEWER
    block_a, block_b = send(pop_func, chars_a), send(pop_func, chars_b)

    # logger.debug('blocks are equal')
    return return_if_no_b if block_b.size == 0

    compare_blocks(block_a, block_b)
  end

  def pop_digits(char_list)
    # logger.debug('pop_digits(%s)', char_list)
    digits = []
    while char_list.any? and char_list.first =~ /^\d/
      digits.append(char_list.shift)
    end

    # logger.debug('got digits: %s', digits)
    # logger.debug('updated char list: %s', char_list)
    digits
  end

  def compare_blocks(block_a, block_b)
    # logger.debug('compare_blocks(%s, %s)', block_a, block_b)
    if block_a[0] =~ /^\d/
      trim_zeros(block_a, block_b)
      if block_a.size != block_b.size
        # logger.debug('block lengths are not equal')
        return block_a.size > block_b.size ? A_NEWER : B_NEWER
      end
    end

    block_a <=> block_b
  end

  def trim_zeros(*char_lists)
    for char_list in char_lists
      while char_list.any? and char_list.first == '0'
        char_list.shift
      end
    end
  end

  def pop_letters(char_list)
    # logger.debug('pop_letters(%s)', char_list)
    letters = []
    while char_list.any? and char_list.first =~ /^[[:alpha:]]/
      letters << char_list.shift
    end
    # logger.debug('got letters: %s', letters)
    # logger.debug('updated char list: %s', char_list)
    return letters
  end
end

