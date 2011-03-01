require 'zlib'

#
# A mutation of "open" that lets you read/write gzip files, as well as
# regular files.
#
# (NOTE: gzip detection is purely based on the filename.)
#
# It accepts a block just like open()!
#
# Example:
#    zopen("test.txt")          #=> #<File:test.txt>
#    zopen("test.txt.gz")       #=> #<Zlib::GzipReader:0xb6c79424>
#    zopen("otherfile.gz", "w") #=> #<Zlib::GzipWriter:0x7fe30448>>
#    zopen("test.txt.gz") { |f| f.read } # reads the contents of the .gz file, then closes the file automatically.
#
def zopen(filename, mode="r")

  file = open(filename, mode)
  
  if filename =~ /\.gz$/
    case mode
    when "r", "rb"
      file = Zlib::GzipReader.new(file) 
    when "w", "wb"
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
