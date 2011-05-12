require 'epitools/basetypes'

class Path

  ## initializers
  
  def initialize(newpath)
    self.path = newpath
  end

  def self.glob(str)
    Dir[str].map { |entry| new(entry) }
  end
  
  def self.[](str)
    if str =~ /[\?\*]/ and not str =~ /\\[\?\*]/  # contains glob chars? (unescaped) 
      glob(str)
    else
      new(str)
    end      
  end

  
  ## setters
  
  attr_writer :base
  attr_writer :dirs
  
  def path=(newpath)
    if File.exists? newpath
      if File.directory? newpath
        self.dir = newpath
      else
        self.dir, self.filename = File.split(newpath)
      end
    else
      if newpath[-1..-1] == File::SEPARATOR # ends in '/'
        self.dir = newpath
      else 
        self.dir, self.filename = File.split(newpath)
      end
    end
  end
  
  def filename=(newfilename)
    if newfilename.nil?
      @ext, @base = nil, nil
    else
      ext = File.extname(newfilename)
      
      if ext.blank?
        @ext = nil
        @base = newfilename
      else
        self.ext = ext
        if pos = newfilename.rindex(ext)
          @base = newfilename[0...pos]
        end
      end
    end
  end
   
  def dir=(newdir)
    @dirs = File.expand_path(newdir).split(File::SEPARATOR)[1..-1]
  end
  
  def ext=(newext)
    if newext.blank?
      @ext = nil
    elsif newext[0] == ?.
      @ext = newext[1..-1]
    else
      @ext = newext
    end
  end

  
  ## getters
   
  # The directories in the path, split into an array. (eg: ['usr', 'src', 'linux'])
  attr_reader :dirs   
  
  # The filename without an extension 
  attr_reader :base
  
  # The file extension, including the . (eg: ".mp3") 
  attr_reader :ext

  # Joins and returns the full path  
  def path
    if d = dir
      File.join(d, (filename || "") )
    else
      ""
    end
  end
  
  # The current directory (with a trailing /)
  def dir
    if dirs 
      File::SEPARATOR + File.join(*dirs)
    else
      nil
    end
  end
  
  def filename
    if base
      if ext
        base + "." + ext
      else
        base
      end
    else
      nil
    end
  end

  
  ## fstat info
  
  def exists?
    File.exists? path
  end

  def size
    File.size path
  end
  
  def mtime
    File.mtime path
  end
  
  def dir?
    File.directory? path
  end
  
  def file?
    File.file? path
  end
  
  def symlink?
    File.symlink? path
  end

  
  ## aliases
  
  alias_method :to_path,    :path
  alias_method :to_str,     :path
  alias_method :to_s,       :path

  alias_method :pathname,   :path
  alias_method :basename,   :base
  alias_method :basename=,  :base=
  alias_method :extname,    :ext
  alias_method :extname=,   :ext=
  alias_method :dirname,    :dir
  alias_method :dirname=,   :dir=
  alias_method :extension,  :ext
  alias_method :extension=, :ext=
  alias_method :directory,  :dir
  alias_method :directory=, :dir=

  alias_method :directory?, :dir?
  

  ## comparisons

  include Comparable
  
  def <=>(other)
    self.path <=> other.path
  end

  
  ## appending
  
  #
  # Path["/etc"]/"passwd" == Path["/etc/passwd"]
  #
  def /(other)
    Path.new( File.join(self, other) )
  end  
  
  
  ## opening/reading files
  
  def open(mode="rb", &block)
    if block_given?
      File.open(path, mode, &block)
    else
      File.open(path, mode)
    end
  end
  
  def read(length=nil, offset=nil)
    File.read(path, length, offset)
  end
  
  def ls
    Path[File.join(path, "*")]
  end
  
end

#
# Path("/some/path") is an alias for Path["/some/path"]
#
def Path(*args)
  Path[*args]
end

