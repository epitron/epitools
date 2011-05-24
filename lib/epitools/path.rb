require 'epitools'

class Path
  
  ## initializers

  def initialize(newpath)
    self.path = newpath
  end

  def self.glob(str)
    Dir[str].map { |entry| new(entry) }
  end
  
  def self.[](str)
    if str =~ %r{^[a-z\-]+://}i # URL?
      Path::URL.new(str)
    elsif str =~ /[\?\*]/ and not str =~ /\\[\?\*]/  # contains glob chars? (unescaped) 
      glob(str)
    else
      new(str)
    end      
  end

  def self.tmpfile(prefix="tmp")
    path = Path[ Tempfile.new(prefix).path ]
    yield path if block_given?
    path
  end
  alias_class_method :tempfile, :tmpfile  
  
  def self.home
    Path[ENV['HOME']]
  end
  
  def self.pwd
    File.expand_path Dir.pwd
  end
  
  def self.pushd
    @@dir_stack ||= []
    @@dir_stack.push pwd
  end
  
  def self.popd
    @@dir_stack ||= [pwd]
    @@dir_stack.pop
  end
  
  def self.cd(dest); Dir.chdir(dest); end
  
  def self.ls(path); Path[path].ls  end
  
  def self.ls_r(path); Path[path].ls_r; end
  
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
      if newpath.endswith(File::SEPARATOR) # ends in '/'
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
    elsif newext.startswith('.')
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
  
  def ctime
    File.ctime path
  end
  
  def atime
    File.atime path
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
  
  def uri?
    false
  end
  
  def url?
    uri?
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
  
  def ls; Path[File.join(path, "*")]; end

  def ls_r; Path[File.join(path, "**/*")]; end

  
  ## modifying files

  #
  # Append
  #
  def append(data=nil)
    self.open("ab") do |f|
      if data and not block_given?
        f.write(data)
      else
        yield f
      end
    end    
  end
  alias_method :<<, :append
  
  #
  # Write a string, truncating the file
  #
  def write(data=nil)
    self.open("wb") do |f|
      if data and not block_given?
        f.write(data)
      else
        yield f
      end
    end    
  end
  
  #
  # Examples:
  #   Path["SongySong.mp3"].rename(:basename=>"Songy Song")
  #   Path["Songy Song.mp3"].rename(:ext=>"aac")
  #   Path["Songy Song.aac"].rename(:dir=>"/music2")
  #   Path["/music2/Songy Song.aac"].exists? #=> true
  #  
  def rename(options)
    raise "Options must be a Hash" unless options.is_a? Hash
    dest = self.with(options)
    
    raise "Error: destination (#{dest.inspect}) already exists" if dest.exists?
    File.rename(path, dest)
    
    self.path = dest.path # become dest
  end

  #
  # Renames the file the specified full path (like Dir.rename.)
  #  
  def rename_to(path)
    rename :path=>path
  end
  alias_method :move,       :rename
  alias_method :ren,        :rename  

  def delete!
    File.unlink(self)
  end
  alias_method :"unlink!", :"delete!"

  def mkdir
    
  end
  
  def mkdir_p
    if exists?
      raise "Error: Path already exists."
    else
      FileUtils.mkdir_p(path)
    end
  end
  
  def cp_r(dest)
    FileUtils.cp_r(path, dest) #if Path[dest].exists?
  end
  
  def join(other)
    if uri?
      Path[URI.join(path, other).to_s]
    else
      Path[File.join(path, other)]
    end
  end
  
  def truncate
    File.truncate(self)
  end
  
    
  
  
  ## Checksums
  
  def sha1
    Digest::SHA1.file(self).hexdigest
  end
  
  def sha2
    Digest::SHA2.file(self).hexdigest
  end
  
  def md5
    Digest::MD5.file(self).hexdigest
  end
  
  alias_method :md5sum, :md5

end

#
# A wrapper for URL objects
#
class Path::URL < Path

  attr_reader :uri
  
  def initialize(uri)
    @uri = URI.parse(uri)
    self.path = @uri.path
  end
  
  def uri?
    true
  end
  
  def host
    uri.host
  end
  
  def query
    if query = uri.query
      query.to_params
    else
      nil
    end
  end
  
  def to_s
    uri.to_s
  end
  
end


#
# Path("/some/path") is an alias for Path["/some/path"]
#
def Path(*args)
  Path[*args]
end

if $0 == __FILE__
  require 'ruby-debug'
  #Path.pry
  #Path["http://google.com/"].pry
  debugger
  Path["?"]
end
