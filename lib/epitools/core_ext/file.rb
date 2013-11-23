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
  #
  def read_backwards(length)
    old_pos = pos

    if length > pos
      seek(0)
    else
      seek(-length, IO::SEEK_CUR)
    end

    new_pos = pos
    data = read(old_pos - new_pos)
    seek(new_pos)

    data
  end

  #
  # Read each line of file backwards (from the current position.)
  #
  def reverse_each_from_current_pos
    return to_enum(:reverse_each_from_current_pos) unless block_given?

    fragment = readline rescue ""

    loop do
      data = read_backwards(4096) + fragment
      loc  = data.size-1

      # NOTE: `rindex(str, loc)` includes the character at `loc`
      while index = data.rindex("\n", loc-1)
        line = data[index+1..loc]
        yield line
        loc = index
      end

      fragment = data[0..loc]

      break if pos == 0 # we're done reading!
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
      data = read_backwards(blocksize)

      if index = data.rindex(string, rindex_end)
        seek(index+string.size, IO::SEEK_CUR)
        break
      elsif pos == 0
        break
      end
    end
  end

end
