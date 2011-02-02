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
  
  def path=(newpath)
    if File.exists? newpath
      if File.directory? newpath
        self.dir = newpath
      else
        self.dir, self.filename = File.split(newpath)
      end
    else
      if path[-1..-1] == File::SEPARATOR
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
        @ext = ext
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
    if newext.nil? or newext[0] == ?.
      @ext = newext
    else
      @ext = "." + newext
    end
  end

  
  ## getters

  attr_reader :dirs, :base, :ext
  
  def path
    d = dir
    f = filename
    if d
      File.join(d, (f || "") )
    else
      ""
    end
  end
  
  def dir
    if dirs 
      File::SEPARATOR + File.join(*dirs)
    else
      nil
    end
  end
  
  def filename
    if base
      base + (ext || "")
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
  
end
