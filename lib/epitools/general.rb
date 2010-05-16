def zopen(filename)
  require 'zlib'

  file = open(filename)
  file = Zlib::GzipReader.new(file) if filename =~ /\.gz$/

  if block_given?
    yield file
    file.close
  else
    file
  end
end
