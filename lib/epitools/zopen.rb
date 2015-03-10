require 'zlib'

COMPRESSORS = {
  ".gz"  => "gzip",
  ".xz"  => "xz",
  ".bz2" => "bzip2"
}

#
# A mutation of "open" that lets you read/write gzip files, as well as
# regular files.
#
# (NOTE: gzip detection is based on the filename, not the contents.)
#
# It accepts a block just like open()!
#
# Example:
#    zopen("test.txt")          #=> #<File:test.txt>
#    zopen("test.txt.gz")       #=> #<Zlib::GzipReader:0xb6c79424>
#    zopen("otherfile.gz", "w") #=> #<Zlib::GzipWriter:0x7fe30448>>
#    zopen("test.txt.gz") { |f| f.read } # read the contents of the .gz file, then close the file handle automatically.
#
def zopen(path, mode="rb")
  ext = File.extname(path).downcase

  if ext == ".gz"
    io = open(path, mode)
    case mode
    when "r", "rb"
      io = Zlib::GzipReader.new(io)
    when "w", "wb"
      io = Zlib::GzipWriter.new(io)
    else
      raise "Unknown mode: #{mode.inspect}. zopen only supports 'r' and 'w'."
    end
  elsif bin = COMPRESSORS[ext]
    io = IO.popen([bin, "-d" ,"-c", path])
  end
  
  if block_given?
    result = yield(io)
    io.close
    result
  else
    io
  end
  
end
