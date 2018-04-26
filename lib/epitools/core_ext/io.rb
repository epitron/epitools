require 'epitools/minimal'

class IO

  unless IO.respond_to? :copy_stream
    #
    # IO.copy_stream backport
    #
    def self.copy_stream(input, output)
      while chunk = input.read(8192)
        output.write(chunk)
      end
    end
  end

  #
  # Iterate over each line of the stream, yielding the line and the byte offset of the start of the line in the file
  #
  def each_line_with_offset
    return to_enum(:each_line_with_offset) unless block_given?

    offset = 0

    each_line do |line|
      yield line, offset
      offset += line.bytesize
    end
  end

end


