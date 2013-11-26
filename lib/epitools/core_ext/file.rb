require 'epitools/minimal'

#
# Beginning of File reached! (Raised when reading a file backwards.)
#
class BOFError < Exception; end

class File

  #
  # A much faster `reverse_each` implementation.
  #
  def reverse_each(&block)
    return to_enum(:reverse_each) unless block_given?

    seek_end
    reverse_each_from_current_pos(&block)
  end

  #
  # Read the previous `length` bytes. After the read, `pos` will be at the beginning of the region that you just read.
  # Returns `nil` when the beginning of the file is reached.
  #
  # If the `block_aligned` argument is `true`, reads will always be aligned to file positions which are multiples of 512 bytes.
  # (This should increase performance slightly.)
  #
  def reverse_read(length, block_aligned=false)
    raise "length must be a multiple of 512" if block_aligned and length % 512 != 0

    b = pos

    if block_aligned
      misalignment = b % length
      length += misalignment
    end

    return nil if b == 0

    # |---a------b---|  <- b is current pos, read from a to b, end up at a

    if length > b
      seek(0)
    else
      seek(-length, IO::SEEK_CUR)
    end

    a = pos

    data = read(b - a)
    seek(a)

    data
  end


  #
  # Read each line of file backwards (from the current position.)
  #
  def reverse_each_from_current_pos
    return to_enum(:reverse_each_from_current_pos) unless block_given?

    fragment = readline rescue ""

    while data = reverse_read(4096)
      data += fragment

      loc  = data.size-1

      # NOTE: `rindex(str, loc)` includes the character at `loc`
      while index = data.rindex("\n", loc-1)
        line = data[index+1..loc]
        yield line
        loc = index
      end

      fragment = data[0..loc]
    end

    yield fragment
  end

  #
  # Seek to `EOF`
  #
  def seek_end
    seek(0, IO::SEEK_END)
  end

  #
  # Read the previous line (leaving `pos` at the beginning of the string that was read.)
  #
  def reverse_readline
    raise BOFError.new("beginning of file reached") if pos == 0

    seek_backwards_to("\n", 512, -2)
    new_pos = pos
    data = readline
    seek(new_pos)
    data
  end

  #
  # Scan backwards in the file until `string` is found, and set the IO's +pos+ to the first character after the matched string.
  # 
  def seek_backwards_to(string, blocksize=512, rindex_end=-1)
    loop do
      data = reverse_read(blocksize)

      if index = data.rindex(string, rindex_end)
        seek(index+string.size, IO::SEEK_CUR)
        break
      elsif pos == 0
        break
      end
    end
  end

end
