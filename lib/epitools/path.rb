#
# TODOs:
#   * Relative paths
#   * Fix Path#/: If it contains glob chars, but a file already exists with that name, assume we're not globbing (fixes problems with {}, [], etc.)

require 'epitools/minimal'
require 'epitools/core_ext/enumerable'
require 'epitools/core_ext/string'

#
# Path: An object-oriented wrapper for files. (Combines useful methods from FileUtils, File, Dir, and more!)
#
# To create a path object, or array of path objects, throw whatever you want into Path[]:
#
#  These returns a single path object:
#    passwd      = Path["/etc/passwd"]
#    also_passwd = Path["/etc"] / "passwd"         # joins two paths
#    parent_dir  = Path["/usr/local/bin"] / ".."   # joins two paths (up one dir)
#
#  These return an array of path objects:
#    pictures   = Path["photos/*.{jpg,png}"]   # globbing
#    notes      = Path["notes/2014/**/*.txt"]  # recursive globbing
#    everything = Path["/etc"].ls
#
# Each Path object has the following attributes, which can all be modified:
#
#    path     => the absolute path, as a string
#    filename => just the name and extension
#    basename => just the filename (without extension)
#    ext      => just the extension
#    dir      => just the directory
#    dirs     => an array of directories
#
# Some commonly used methods:
#
#   path.file?
#   path.exists?
#   path.dir?
#   path.mtime
#   path.xattrs
#   path.symlink?
#   path.broken_symlink?
#   path.symlink_target
#   path.executable?
#   path.chmod(0o666)
#
# Interesting examples:
#
#   Path["*.jpeg"].each { |path| path.rename(:ext=>"jpg") } # renames .jpeg to .jpg
#
#   files     = Path["/etc"].ls         # all files in directory
#   morefiles = Path["/etc"].ls_R       # all files in directory tree
#
#   Path["*.txt"].each(&:gzip!)
#
#   Path["filename.txt"] << "Append data!"     # appends data to a file
#
#   string = Path["filename.txt"].read         # read all file data into a string
#   json   = Path["filename.json"].read_json   # read and parse JSON
#   doc    = Path["filename.html"].read_html   # read and parse HTML
#   xml    = Path["filename.xml"].parse        # figure out the format and parse it (as XML)
#
#   Path["saved_data.marshal"].write(data.marshal)   # Save your data!
#   data = Path["saved_data.marshal"].unmarshal      # Load your data!
#
#   Path["unknown_file"].mimetype              # sniff the file to determine its mimetype
#   Path["unknown_file"].mimetype.image?       # ...is this some kind of image?
#
#   Path["otherdir/"].cd do                    # temporarily change to "otherdir/"
#     p Path.ls
#   end
#   p Path.ls
#
# The `Path#dirs` attribute is a split up version of the directory
# (eg: Path["/usr/local/bin"].dirs => ["usr", "local", "bin"]).
#
# You can modify the dirs array to change subsets of the directory. Here's an example that
# finds out if you're in a git repo:
#
#   def inside_a_git_repo?
#     path = Path.pwd # start at the current directory
#     while path.dirs.any?
#       if (path/".git").exists?
#         return true
#       else
#         path.dirs.pop  # go up one level
#       end
#     end
#     false
#   end
#
# Swap two files:
#
#   a, b = Path["file_a", "file_b"]
#   temp = a.with(:ext => a.ext+".swapping") # return a modified version of this object
#   a.mv(temp)
#   b.mv(a)
#   temp.mv(b)
#
# Paths can be created for existant and non-existant files.
#
# To create a nonexistant path object that thinks it's a directory, just add a '/' at the end.
# (eg: Path["/etc/nonexistant/"]).
#
# Performance has been an important factor in Path's design, so doing crazy things with Path
# usually doesn't kill performance. Go nuts!
#
#
class Path

  include Enumerable

  # The directories in the path, split into an array. (eg: ['usr', 'src', 'linux'])
  attr_reader :dirs

  # The filename without an extension
  attr_reader :base

  # The file extension, including the . (eg: ".mp3")
  attr_reader :ext


  ###############################################################################
  # Initializers
  ###############################################################################

  def initialize(newpath, hints={})
    send("path=", newpath, hints)

    # if hints[:unlink_when_garbage_collected]
    #   backup_path = path.dup
    #   puts "unlinking #{backup_path} after gc!"
    #   ObjectSpace.define_finalizer self do |object_id|
    #     File.unlink backup_path
    #   end
    # end
  end

  def initialize_copy(other)
    @dirs = other.dirs && other.dirs.dup
    @base = other.base && other.base.dup
    @ext  = other.ext  && other.ext.dup
  end

  def self.escape(str)
    Shellwords.escape(str)
  end

  def self.glob(str, hints={})
    Dir[str].map { |entry| new(entry, hints) }
  end

  def self.[](path)
    case path
    when Path
      path
    when String

      if path =~ %r{^[a-z\-]+://}i # URL?
        Path::URI.new(path)

      else
        # TODO: highlight backgrounds of codeblocks to show indent level & put boxes (or rules?) around (between?) double-spaced regions
        path = Path.expand_path(path)
        unless path =~ /(^|[^\\])[\?\*\{\}]/ # contains unescaped glob chars?
          new(path)
        else
          glob(path)
        end

      end

    end
  end

  ###############################################################################
  # Setters
  ###############################################################################

  attr_writer :base
  attr_writer :dirs

  #
  # This is the core that initializes the whole class.
  #
  # Note: The `hints` parameter contains options so `path=` doesn't have to touch the filesytem as much.
  #
  def path=(newpath, hints={})
    if hints[:type] or File.exists? newpath
      if hints[:type] == :dir or File.directory? newpath
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

    # FIXME: Make this work with globs.
    if hints[:relative]
      update(relative_to(Path.pwd))
    elsif hints[:relative_to]
      update(relative_to(hints[:relative_to]))
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
    dirs  = File.expand_path(newdir).split(File::SEPARATOR)
    dirs  = dirs[1..-1] if dirs.size > 0

    @dirs = dirs
  end

  # TODO: Figure out how to fix the 'path.with(:ext=>ext+".other")' problem (when 'ext == nil')...

  def ext=(newext)
    if newext.blank?
      @ext = nil
      return
    end

    newext = newext[1..-1] if newext.startswith('.')

    if newext['.']
      self.filename = basename + '.' + newext
    else
      @ext = newext
    end
  end

  #
  # Clear out the internal state of this object, so that it can be reinitialized.
  #
  def reset!
    [:@dirs, :@base, :@ext].each { |var| remove_instance_variable(var) rescue nil  }
    self
  end

  #
  # Reload this path (updates cached values.)
  #
  def reload!
    temp = path
    reset!
    self.path = temp
    @attrs = nil

    self
  end

  def update(other)
    @dirs = other.dirs
    @base = other.base
    @ext  = other.ext
  end

  ## getters

  # Joins and returns the full path
  def path
    if d = dir
      File.join(d, (filename || "") )
    else
      ""
    end
  end

  #
  # Is this a relative path?
  #
  def relative?
    # FIXME: Need a Path::Relative subclass, so that "dir/filename" can be valid.
    #        (If the user changes dirs, the relative path should change too.)
    dirs.first == ".."
  end

  #
  # Path relative to current directory (Path.pwd)
  #
  def relative
    relative_to(pwd)
  end

  def relative_to(anchor)
    anchor = anchor.to_s
    anchor += "/" unless anchor[/\/$/]
    to_s.gsub(/^#{Regexp.escape(anchor)}/, '')
  end

  # The current directory (with a trailing /)
  def dir
    if dirs
      if relative?
        File.join(*dirs)
      else
        File.join("", *dirs)
      end
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

  def name
    filename || "#{dirs.last}/"
  end

  def exts
    extensions = basename.split('.')[1..-1]
    extensions += [@ext] if @ext
    extensions
  end

  ###############################################################################
  # inspect
  ###############################################################################

  def inspect
    "#<Path:#{path}>"
  end

  ###############################################################################
  # fstat
  ###############################################################################

  def exists?
    File.exists? path
  end

  def size
    File.size(path)
  rescue Errno::ENOENT
    -1
  end

  def lstat
    @lstat ||= File.lstat self    # to cache, or not to cache? that is the question.
    # File.lstat self                 # ...answer: not to cache!
  end

  def mode
    lstat.mode
  end

  def mtime
    lstat.mtime
  end

  def mtime=(new_mtime)
    File.utime(atime, new_mtime, path)
    @lstat = nil
    new_mtime
  end

  def ctime
    lstat.ctime
  end

  def atime
    lstat.atime
  end

  def atime=(new_atime)
    File.utime(new_atime, mtime, path)
    @lstat = nil
    new_atime
  end

  # FIXME: Does the current user own this file?
  def owner?
    raise "STUB"
  end

  def executable?
    mode & 0o111 > 0
  end
  alias_method :exe?, :executable?

  def writable?
    mode & 0o222 > 0
  end

  def readable?
    mode & 0o444 > 0
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

  def broken_symlink?
    File.symlink?(path) and not File.exists?(path)
  end

  def symlink_target
    target = File.readlink(path.gsub(/\/$/, ''))
    if target.startswith("/")
      Path[target]
    else
      Path[dir] / target
    end
  end
  alias_method :readlink, :symlink_target
  alias_method :target,   :symlink_target

  def hidden?
    thing = filename ? filename : dirs.last
    !!thing[/^\../]
  end

  def uri?; false; end
  def url?; uri?; end

  def child_of?(parent)
    parent.parent_of? self
  end

  def parent_of?(child)
    dirs == child.dirs[0...dirs.size]
  end

  #
  # Does the file or directory name start with a "."?
  #
  def hidden?
    (dir? ? dirs.last : filename)[/^\../]
  end

  ###############################################################################
  # Comparisons
  ###############################################################################

  include Comparable

  #
  # An array of attributes which will be used sort paths (case insensitive, directories come first)
  #
  def sort_attrs
    [(filename ? 1 : 0), path.downcase]
  end

  def <=>(other)
    case other
    when Path
      sort_attrs <=> other.sort_attrs
    when String
      path <=> other
    else
      raise "Invalid comparison: Path to #{other.class}"
    end
  end

  def ==(other)
    self.path == other.to_s
  end
  alias_method :eql?, :==

  def hash; path.hash; end

  ###############################################################################
  # Joining paths
  ###############################################################################

  #
  # Path["/etc"].join("anything{}").path == "/etc/anything{}"
  # (globs ignored)
  #
  def join(other)
    Path.new File.join(self, other)
  end

  #
  # Path["/etc"]/"passwd" == Path["/etc/passwd"]
  # (globs permitted)
  #
  def /(other)
    # / <- fixes jedit syntax highlighting bug.
    # TODO: make it work for "/dir/dir"/"/dir/file"
    #Path.new( File.join(self, other) )
    Path[ File.join(self, other) ]
  end

  ###############################################################################
  # Xattrs
  ###############################################################################

  #
  # Read xattrs from file (requires "getfattr" to be in the path)
  #
  def self.getfattr(path)
    # # file: Scissor_Sisters_-_Invisible_Light.flv
    # user.m.options="-c"

    cmd = %w[getfattr -d -m - -e base64] + [path]

    attrs = {}

    IO.popen(cmd, "rb", :err=>[:child, :out]) do |io|
      io.each_line do |line|
        if line =~ /^([^=]+)=0s(.+)/
          key   = $1
          value = $2.from_base64 # unpack base64 string
          # value = value.encode("UTF-8", "UTF-8") # set string's encoding to UTF-8
          value = value.force_encoding("UTF-8").scrub  # set string's encoding to UTF-8
          # value = value.encode("UTF-8", "UTF-8")  # set string's encoding to UTF-8

          attrs[key] = value
        end
      end
    end

    attrs
  end

  #
  # Set xattrs on a file (requires "setfattr" to be in the path)
  #
  def self.setfattr(path, key, value)
    cmd = %w[setfattr]

    if value == nil
      # delete
      cmd += ["-x", key]
    else
      # set
      cmd += ["-n", key, "-v", value.to_s.strip]
    end

    cmd << path

    IO.popen(cmd, "rb", :err=>[:child, :out]) do |io|
      result = io.each_line.to_a
      error = {:cmd => cmd, :result => result.to_s}.inspect
      raise error if result.any?
    end
  end

  #
  # Return a hash of all of this file's xattrs.
  # (Metadata key=>valuse pairs, supported by most modern filesystems.)
  #
  def attrs
    @attrs ||= Path.getfattr(path)
  end
  alias_method :xattrs, :attrs

  #
  # Set this file's xattrs. (Optimized so that only changed attrs are written to disk.)
  #
  def attrs=(new_attrs)
    changes = attrs.diff(new_attrs)

    changes.each do |key, (old, new)|
      case new
      when String, Numeric, true, false, nil
        self[key] = new
      else
        raise "Error: Can't use a #{new.class} as an xattr value. Try passing a String."
      end
    end
  end

  #
  # Retrieve one of this file's xattrs
  #
  def [](key)
    attrs[key]
  end

  #
  # Set this file's xattr
  #
  def []=(key, value)
    Path.setfattr(path, key, value)
    @attrs = nil # clear cached xattrs
  end

  ###############################################################################
  # Opening/Reading files
  ###############################################################################

  #
  # Open the file (default: read-only + binary mode)
  #
  def open(mode="rb", &block)
    if block_given?
      File.open(path, mode, &block)
    else
      File.open(path, mode)
    end
  end
  alias_method :io, :open
  alias_method :stream, :open

  #
  # Read bytes from the file (just a wrapper around File.read)
  #
  def read(length=nil, offset=nil)
    File.read(path, length, offset)
  end

  #
  # Read the contents of a file one chunk at a time (default chunk size is 16k)
  #
  def each_chunk(chunk_size=2**14)
    open do |io|
      yield io.read(chunk_size) until io.eof?
    end
  end


  #
  # All the lines in this file, chomped.
  #
  def each_line(&block)
    open { |io| io.each_line { |line| block.call(line.chomp) } }
  end
  alias_method :each,       :each_line
  alias_method :lines,      :each_line
  alias_method :nicelines,  :each_line
  alias_method :nice_lines, :each_line


  #
  # Yields all matching lines in the file (by returning an Enumerator, or receiving a block)
  #
  def grep(pat)
    return to_enum(:grep, pat).to_a unless block_given?

    each_line do |line|
      yield line if line =~ pat
    end
  end

  def unmarshal
    read.unmarshal
  end

  #
  # Returns all the files in the directory that this path points to
  #
  def ls
    Dir.foreach(path).
      reject {|fn| fn == "." or fn == ".." }.
      flat_map {|fn| self / fn }
  end

  #
  # Returns all files in this path's directory and its subdirectories
  #
  def ls_r(symlinks=false)
    # glob = symlinks ? "**{,/*/**}/*" : "**/*"
    # Path[File.join(path, glob)]
    Find.find(path).drop(1).map {|fn| Path.new(fn) }
  end
  alias_method :ls_R, :ls_r

  #
  # Returns all the directories in this path
  #
  def ls_dirs
    ls.select(&:dir?)
    #Dir.glob("#{path}*/", File::FNM_DOTMATCH).map { |s| Path.new(s, :type=>:dir) }
  end

  #
  # Returns all the files in this path
  #
  def ls_files
    ls.select(&:file?)
    #Dir.glob("#{path}*", File::FNM_DOTMATCH).map { |s| Path.new(s, :type=>:file) }
  end

  #
  # Returns all neighbouring directories to this path
  #
  def siblings
    Path[dir].ls - [self]
  end

  #
  # Like the unix `touch` command
  # (if the file exists, update its timestamp, otherwise create a new file)
  #
  def touch
    open("a") { }
    self
  end


  ###############################################################################
  # Modifying files
  ###############################################################################

  #
  # Append data to this file (accepts a string, an IO, or it can yield the file handle to a block.)
  #
  def append(data=nil)
    # FIXME: copy_stream might be inefficient if you're calling it a lot. Investigate!
    self.open("ab") do |f|
      if data and not block_given?
        if data.is_an? IO
          IO.copy_stream(data, f)
        else
          f.write(data)
        end
      else
        yield f
      end
    end
    self
  end
  alias_method :<<, :append

  #
  # Append data, with a newline at the end
  #
  def puts(data=nil)
    append data
    append "\n" unless data and data[-1] == "\n"
  end

  #
  # Overwrite the data in this file (accepts a string, an IO, or it can yield the file handle to a block.)
  #
  def write(data=nil)
    self.open("wb") do |f|
      if data and not block_given?
        if data.is_an? IO
          IO.copy_stream(data, f)
        else
          f.write(data)
        end
      else
        yield f
      end
    end
  end


  ###############################################################################
  # Parsing files
  ###############################################################################

  #
  # Parse the file based on the file extension.
  # (Handles json, html, yaml, xml, csv, marshal, and bson.)
  #
  def parse
    case ext.downcase
    when 'json'
      read_json
    when 'html', 'htm'
      read_html
    when 'yaml', 'yml'
      read_yaml
    when 'xml', 'rdf', 'rss'
      read_xml
    when 'csv'
      read_csv
    when 'marshal'
      read_marshal
    when 'bson'
      read_bson
    else
      raise "Unrecognized format: #{ext}"
    end
  end

  #
  # Treat each line of the file as a json object, and parse them all, returning an array of hashes
  #
  def parse_lines
    each_line.map { |line| JSON.parse line }
  end

  # Parse the file as JSON
  def read_json
    JSON.load(io)
  end
  alias_method :from_json, :read_json

  # Convert the object to JSON and write it to the file (overwriting the existing file).
  def write_json(object)
    write object.to_json
  end


  def read_html
    Nokogiri::HTML(io)
  end
  alias_method :from_html, :read_html


  # Convert the object to YAML and write it to the file (overwriting the existing file).
  def write_yaml(object)
    write object.to_yaml
  end

  # Parse the file as YAML
  def read_yaml
    YAML.load(io)
  end
  alias_method :from_yaml, :read_yaml

  # Parse the file as CSV
  def read_csv(opts={})
    CSV.open(io, opts).each
  end
  alias_method :from_csv, :read_csv

  # Parse the file as XML
  def read_xml
    Nokogiri::XML(io)
  end

  # Parse the file as a Ruby Marshal dump
  def read_marshal
    Marshal.load(io)
  end

  # Serilize an object to Ruby Marshal format and write it to this path
  def write_marshal(object)
    write object.marshal
  end

  # Parse the file as BSON
  def read_bson
    BSON.deserialize(read)
  end

  # Serilize an object to BSON format and write it to this path
  def write_bson(object)
    write BSON.serialize(object)
  end

  #
  # Change into the directory. If a block is given, it changes into
  # the directory for the duration of the block, then puts you back where you
  # came from once the block is finished.
  #
  def cd(&block)
    Path.cd(path, &block)
  end

  #
  # A private method for handling arguments to mv and rename.
  #
  def arg_to_path(arg)
    case arg
    when String, Path
      Path[arg]
    when Hash
      self.with(arg)
    else
      raise "Error: argument must be a path (a String or a Path), or a hash of attributes to replace in the Path."
    end
  end
  private :arg_to_path

  #
  # Renames the file, but doesn't change the current Path object, and returns a Path that points at the new filename.
  #
  # Examples:
  #   Path["file"].rename("newfile") #=> Path["newfile"]
  #   Path["SongySong.mp3"].rename(:basename=>"Songy Song")
  #   Path["Songy Song.mp3"].rename(:ext=>"aac")
  #   Path["Songy Song.aac"].rename(:dir=>"/music2")
  #   Path["/music2/Songy Song.aac"].exists? #=> true
  #
  def rename(arg)
    dest = arg_to_path(arg)

    raise "Error: destination (#{dest.inspect}) already exists" if dest.exists?
    raise "Error: can't rename #{self.inspect} because source location doesn't exist." unless exists?

    File.rename(path, dest)
    dest
  end
  alias_method :ren, :rename

  #
  # Works the same as "rename", but the destination can be on another disk.
  #
  def mv(arg)
    dest = arg_to_path(arg)

    raise "Error: can't move #{self.inspect} because source location doesn't exist." unless exists?

    FileUtils.mv(path, dest)
    dest
  end
  alias_method :move, :mv

  #
  # Rename the file and change this Path object so that it points to the destination file.
  #
  def rename!(arg)
    update(rename(arg))
  end
  alias_method :ren!, :rename!

  #
  # Moves the file (overwriting the destination if it already exists). Also points the current Path object at the new destination.
  #
  def mv!(arg)
    update(mv(arg))
  end
  alias_method :move!, :mv!

  #
  # Find a backup filename that doesn't exist yet by appending "(1)", "(2)", etc. to the current filename.
  #
  def numbered_backup_file
    return self unless exists?

    n = 1
    loop do
      if dir?
        new_file = with(:dirs => dirs[0..-2] + ["#{dirs.last} (#{n})"])
      else
        new_file = with(:basename => "#{basename} (#{n})")
      end
      return new_file unless new_file.exists?
      n += 1
    end
  end

  #
  # Return a copy of this Path with ".bak" at the end
  #
  def backup_file
    with(:filename => filename+".bak")
  end

  #
  # Rename this file, "filename.ext", to "filename (1).ext" (or (2), or (3), or whatever number is available.)
  # (Does not modify this Path object.)
  #
  def numbered_backup!
    rename(numbered_backup_file)
  end

  #
  # Rename this file, "filename.ext", to "filename.ext.bak".
  # (Does not modify this Path object.)
  #
  def backup!
    rename(backup_file)
  end

  #
  # Generate two almost identical methods: mkdir and mkdir_p
  #
  {
    :mkdir => "Dir.mkdir",
    :mkdir_p =>"FileUtils.mkdir_p"
  }.each do |method, command|
    class_eval %{
      def #{method}
        if exists?
          if directory?
            reload!
          else
            raise "Error: A file by this name already exists."
          end
        else
          #{command} path   # Make the directory
          reload!
        end
        self
      end
    }
  end

  def cp_r(dest)
    FileUtils.cp_r(path, dest) #if Path[dest].exists?
    dest
  end

  #
  # Copy a file to a destination, creating all intermediate directories if they don't already exist
  #
  def cp_p(dest)
    FileUtils.mkdir_p(dest.dir) unless File.directory? dest.dir
    if file?
      FileUtils.cp(path, dest)
    elsif dir?
      FileUtils.cp_r(path, dest)
    end

    dest
  end

  def cp(dest)
    FileUtils.cp(path, dest)
    dest
  end

  def ln_s(dest)
    if dest.startswith("/")
      Path.ln_s(self, dest)
    else
      Path.ln_s(self, self / dest)
    end
  end

  alias_method :symlink_to, :ln_s

  ## Owners and permissions

  #
  # Same usage as `FileUtils.chmod` (because it just calls `FileUtils.chmod`)
  #
  # eg:
  #   path.chmod(0600) # mode bits in octal (can also be 0o600 in ruby)
  #   path.chmod "u=wrx,go=rx", 'somecommand'
  #   path.chmod "u=wr,go=rr", "my.rb", "your.rb", "his.rb", "her.rb"
  #   path.chmod "ugo=rwx", "slutfile"
  #   path.chmod "u=wrx,g=rx,o=rx", '/usr/bin/ruby', :verbose => true
  #
  # Letter things:
  #   "a" :: is user, group, other mask.
  #   "u" :: is user's mask.
  #   "g" :: is group's mask.
  #   "o" :: is other's mask.
  #   "w" :: is write permission.
  #   "r" :: is read permission.
  #   "x" :: is execute permission.
  #   "X" :: is execute permission for directories only, must be used in conjunction with "+"
  #   "s" :: is uid, gid.
  #   "t" :: is sticky bit.
  #   "+" :: is added to a class given the specified mode.
  #   "-" :: Is removed from a given class given mode.
  #   "=" :: Is the exact nature of the class will be given a specified mode.
  #
  def chmod(mode)
    FileUtils.chmod(mode, self)
    self
  end

  def chown(usergroup)
    user, group = usergroup.split(":")
    FileUtils.chown(user, group, self)
    self
  end

  def chmod_R(mode)
    if directory?
      FileUtils.chmod_R(mode, self)
      self
    else
      raise "Not a directory."
    end
  end

  def chown_R(usergroup)
    user, group = usergroup.split(":")
    if directory?
      FileUtils.chown_R(user, group, self)
      self
    else
      raise "Not a directory."
    end
  end

  ## Dangerous methods.

  #
  # Remove a file or directory
  #
  def rm
    raise "Error: #{self} does not exist" unless symlink? or exists? 

    if directory? and not symlink?
      Dir.rmdir(self) == 0
    else
      File.unlink(self) == 1
    end
  end
  alias_method :delete!, :rm
  alias_method :unlink!, :rm
  alias_method :remove!, :rm

  #
  # Shrink or expand the size of a file in-place
  #
  def truncate(offset=0)
    File.truncate(self, offset) if exists?
  end


  ## Checksums

  def sha1
    Digest::SHA1.file(self).hexdigest
  end
  alias_method :sha1sum, :sha1

  def sha2
    Digest::SHA2.file(self).hexdigest
  end
  alias_method :sha2sum, :sha2

  def md5
    Digest::MD5.file(self).hexdigest
  end
  alias_method :md5sum, :md5

  def sha256
    Digest::SHA256.file(self).hexdigest
  end
  alias_method :sha256sum, :sha256

  ## http://ruby-doc.org/stdlib/libdoc/zlib/rdoc/index.html

  #
  # gzip the file, returning the result as a string
  #
  def deflate(level=nil)
    Zlib.deflate(read, level)
  end
  alias_method :gzip, :deflate


  #
  # gunzip the file, returning the result as a string
  #
  def inflate
    Zlib.inflate(read)
  end
  alias_method :gunzip, :inflate

  #
  # Quickly gzip a file, creating a new .gz file, without removing the original,
  # and returning a Path to that new file.
  #
  def gzip!(level=nil)
    gz_file = self.with(:filename=>filename+".gz")

    raise "#{gz_file} already exists" if gz_file.exists?

    open("rb") do |input|
      Zlib::GzipWriter.open(gz_file) do |gzwriter|
        IO.copy_stream(input, gzwriter)
      end
    end

    update(gz_file)
  end

  #
  # Quickly gunzip a file, creating a new file, without removing the original,
  # and returning a Path to that new file.
  #
  def gunzip!
    raise "Not a .gz file" unless ext == "gz"

    regular_file = self.with(:ext=>nil)

    regular_file.open("wb") do |output|
      Zlib::GzipReader.open(self) do |gzreader|
        IO.copy_stream(gzreader, output)
      end
    end

    update(regular_file)
  end

  #
  # Match the full path against a regular expression
  #
  def =~(pattern)
    to_s =~ pattern
  end

  #
  # Find the parent directory. If the `Path` is a filename, it returns the containing directory.
  #
  def parent
    if file?
      with(:filename=>nil)
    else
      with(:dirs=>dirs[0...-1])
    end
  end

  def startswith(s); path.startswith(s); end
  def endswith(s); path.endswith(s); end

  #
  # Follows all symlinks to give the true location of a path.
  #
  if File.respond_to?(:realpath)
    def realpath
      Path.new File.realpath(path)
    end
  else
    def realpath
      require 'pathname'
      Path.new Pathname.new(path).realpath
    end
  end


  #
  # Find the file's mimetype (first from file extension, then by magic)
  #
  def mimetype
    mimetype_from_ext || magic
  end
  alias_method :identify, :mimetype

  #
  # Find the file's mimetype (only using the file extension)
  #
  def mimetype_from_ext
    MimeMagic.by_extension(ext)
  end

  #
  # Find the file's mimetype (by magic)
  #
  def magic
    open { |io| MimeMagic.by_magic(io) }
  end

  #
  # Returns the filetype (as a standard file extension), verified with Magic.
  #
  # (In other words, this will give you the *true* extension, even if the file's
  # extension is wrong.)
  #
  # Note: Prefers long extensions (eg: jpeg over jpg)
  #
  # TODO: rename type => magicext?
  #
  def type
    @cached_type ||= begin

      if file? or symlink?

        ext   = self.ext
        magic = self.magic

        if ext and magic
          if magic.extensions.include? ext
            ext
          else
            magic.ext # in case the supplied extension is wrong...
          end
        elsif !ext and magic
          magic.ext
        elsif ext and !magic
          ext
        else # !ext and !magic
          :unknown
        end

      elsif dir?
        :directory
      end

    end
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

  alias_method :exist?,     :exists?

  ############################################################################
  ## Class Methods

  #
  # FileUtils-like class-method versions of instance methods
  # (eg: `Path.mv(src, dest)`)
  #
  # Note: Methods with cardinality 1 (`method/1`) are instance methods that take
  # one parameter, and hence, class methods that take two parameters.
  #
  AUTOGENERATED_CLASS_METHODS = %w[
    mkdir
    mkdir_p
    sha1
    sha2
    md5
    rm
    truncate
    realpath
    mv/1
    move/1
    chmod/1
    chown/1
    chown_R/1
    chmod_R/1
  ].each do |spec|
    meth, cardinality = spec.split("/")
    cardinality       = cardinality.to_i

    class_eval %{
      def self.#{meth}(path#{", *args" if cardinality > 0})
        Path[path].#{meth}#{"(*args)" if cardinality > 0}
      end
    }
  end


  #
  # Same as File.expand_path, except preserves the trailing '/'.
  #
  def self.expand_path(orig_path)
    new_path = File.expand_path orig_path
    new_path << "/" if orig_path.endswith "/"
    new_path
  end

  #
  # TODO: Remove the tempfile when the Path object is garbage collected or freed.
  #
  def self.tmpfile(prefix="tmp")
    path = Path.new Tempfile.new(prefix).path, unlink_when_garbage_collected: true
    yield path if block_given?
    path
  end
  alias_class_method :tempfile, :tmpfile
  alias_class_method :tmp,      :tmpfile


  #
  # Create a uniqely named directory in /tmp
  #
  def self.tmpdir(prefix="tmp")
    t = tmpfile
    t.rm; t.mkdir # FIXME: These two operations should be made atomic
    t
  end
  alias_class_method :tempdir, :tmpdir

  #
  # User's current home directory
  #
  def self.home
    Path[ENV['HOME']]
  end

  #
  # The current directory
  #
  def self.pwd
    Path.new expand_path(Dir.pwd)
  end

  def self.pushd(destination)
    @@dir_stack ||= []
    @@dir_stack.push pwd
  end

  def self.popd
    @@dir_stack ||= [pwd]
    @@dir_stack.pop
  end

  #
  # Change into the directory "dest". If a block is given, it changes into
  # the directory for the duration of the block, then puts you back where you
  # came from once the block is finished.
  #
  def self.cd(dest)
    dest = Path[dest]

    raise "Can't 'cd' into #{dest}" unless dest.dir?

    if block_given?
      orig = pwd

      Dir.chdir(dest)
      result = yield dest
      Dir.chdir(orig)

      result
    else
      Dir.chdir(dest)
      dest
    end
  end

  def self.ls(path); Path[path].ls  end

  def self.ls_r(path); Path[path].ls_r; end

  def self.ln_s(src, dest)
    FileUtils.ln_s(src, dest)
    Path[dest]
  end

  ## TODO: Verbose mode
  #def self.verbose=(value); @@verbose = value; end
  #def self.verbose; @@verbose ||= false; end

  if Sys.windows?
    PATH_SEPARATOR    = ";"
    BINARY_EXTENSION  = ".exe"
  else
    PATH_SEPARATOR    = ":"
    BINARY_EXTENSION  = ""
  end

  #
  # A clone of `/usr/bin/which`: pass in the name of a binary, and it'll search the PATH
  # returning the absolute location of the binary if it exists, or `nil` otherwise.
  #
  # (Note: If you pass more than one argument, it'll return an array of `Path`s instead of
  #        a single path.)
  #
  def self.which(bin, *extras)
    if extras.empty?
      ENV["PATH"].split(PATH_SEPARATOR).find do |path|
        result = (Path[path] / (bin + BINARY_EXTENSION))
        return result if result.exists?
      end
      nil
    else
      ([bin] + extras).map { |bin| which(bin) }
    end
  end

  #
  # No-op (returns self)
  #
  def to_Path
    self
  end

end


class Path::Relative < Path
  # FIXME: Implement this.
end

#
# A wrapper for URI objects.
#
class Path::URI < Path

  attr_reader :uri

  #
  # TODO: only include certain methods from Path (delegate style)
  #       (eg: remove commands that write)

  def initialize(uri, hints={})
    @uri = ::URI.parse(uri)
    self.path = @uri.path
  end

  def uri?
    true
  end

  #
  # Example:
  #
  # When this is: http://host.com:port/path/filename.ext?param1=value1&param2=value2&...
  #
  def to_s; uri.to_s; end


  #
  # ...this is: 'http'
  #
  def scheme; uri.scheme; end
  alias_method :protocol, :scheme

  %w[http https ftp magnet].each do |s|
    define_method("#{s}?") { scheme[/^#{s}$/i] }
  end

  def http?; super or https?; end

  #
  # ...and this is: 'host.com'
  #
  def host; uri.host; end

  #
  # ...and this is: 80
  #
  def port; uri.port; end

  #
  # ...and this is: {param1: value1, param2: value2, ...etc... }
  #
  def query
    if query = uri.query
      query.to_params
    else
      nil
    end
  end

  def join(other)
    Path.new URI.join(path, other).to_s
  end


  # ...and `path` is /path/filename.ext

  def open(mode="r", &block)
    require 'open-uri'
    if block_given?
      open(to_s, mode, &block)
    else
      open(to_s, mode)
    end
  end

  # Note: open is already aliased to io in parent class.
  def read(*args)
    require 'open-uri'
    case scheme
    when /https?/i
      io.read(*args)
    else
      raise "No connector for #{scheme} yet. Please fix!"
    end
  end

end

