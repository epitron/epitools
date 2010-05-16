require 'zlib'

#
# A mutation of "open" that lets you read/write gzip files, as well as
# regular files. (NOTE: gzip detection is purely based on filename.) 
#
def zopen(filename, mode="r")

  file = open(filename, mode)
  
  if filename =~ /\.gz$/
    case mode
    when "r"
      file = Zlib::GzipReader.new(file) 
    when "w"
      file = Zlib::GzipWriter.new(file) 
    else
      raise "Unknown mode: #{mode.inspect}. zopen only supports 'r' and 'w'."
    end
  end
  
  if block_given?
    result = yield(file)
    file.close
    result
  else
    file
  end
  
end
