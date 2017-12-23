require 'epitools'
require 'epitools/permutations'

describe Path do

  it "initializes and accesses everything" do
    path = Path.new("/blah/what.mp4/.mp3/hello.avi")

    path.dirs.should     == %w[ blah what.mp4 .mp3 ]
    path.dir.should      == "/blah/what.mp4/.mp3"
    path.filename.should == "hello.avi"
    path.ext.should      == "avi"
    path.base.should     == "hello"
  end

  it "dups itself" do
    path = Path.new "/whatever/blah/stuff.ext"
    path2 = path.dup
    path2.path.should == path.path
    path.dirs.pop
    path2.path.should_not == path.path
  end

  it "sizes" do
    path = Path.tmpfile
    path.write("asdfasdf")
    path.size.should == 8

    nonexistant = Path.new("/i/hope/this/doesn't/exist/man")
    nonexistant.size.should == -1
  end

  it "works with relative paths" do
    path = Path.new("../hello.mp3/blah")

    path.filename.should == "blah"
    path.ext.should      == nil

    abs_path             = File.join(File.expand_path(".."), "hello.mp3")
    path.dir.should      == abs_path
  end

  it "'relative_to's" do
    # Path["/etc"].relative_to(Path["/tmp"]).should == "../etc/"
    Path["/etc/passwd"].relative_to("/etc").should == "passwd"
  end

  it "should glob with relative paths" do
    # raise "not implemented"
  end

  it "handles directories" do
    path = Path.new("/etc/")

    path.dirs.should_not == nil
    path.dir.should      == "/etc"
    path.filename.should == nil
  end

  it "replaces ext" do
    path = Path.new("/blah/what.mp4/.mp3/hello.avi")
    path.ext.should == "avi"

    path.ext = "mkv"
    path.ext.should == "mkv"

    path.filename[-4..-1].should == ".mkv"

    path.ext += ".extra"
    path.filename.should == "hello.mkv.extra"
    path.ext.should == "extra"
  end

  it "replaces filename" do
    path             = Path.new(__FILE__)
    path.dir?.should == false

    path.filename    = nil
    path.dir?.should == true
  end

  it "fstats" do
    path = Path.new(__FILE__)

    path.exists?.should     == true
    path.dir?.should        == false
    path.file?.should       == true
    path.symlink?.should    == false
    path.mtime.class.should == Time
  end

  it "globs" do
    path  = Path.new(__FILE__)
    glob  = path.dir + "/*spec.rb"
    specs = Path.glob(glob)
    path.in?(specs).should == true
  end

  it "Path[file] and Path[glob]s" do
    path              = Path.new(__FILE__)
    path.should       == Path[__FILE__]

    glob              = path.dir + "/*spec.rb"
    specs             = Path.glob(glob)
    Path[glob].should == specs
  end

  it "paths can be passed to ruby File methods" do
    path = Path.new(__FILE__)
    data = File.read(path)
    data.size.should > 0
  end

  it "opens & read files" do
    path = Path.new(__FILE__)

    path.open do |f|
      f.read.size.should > 0
    end

    path.read.size.should > 0
  end

  it "reads with length and offset" do
    path = Path.new(__FILE__)

    path.read(25).size.should == 25

    s1 = path.read(25,15)
    s2 = path.read(40)

    s2[15..-1].should == s1
  end

  it "reads/writes various formats (json, yaml, etc.)" do
    data = { "hello" => "there", "amazing" => [1,2,3,4] }

    yaml = Path.tmpfile
    yaml.write_yaml(data)
    yaml.read_yaml.should == data

    json = Path.tmpfile
    json.write_json(data)
    json.read_json.should == data

    data = "<h1>The best webpage in the universe.</h1>"
    html = Path.tmpfile
    html.write data
    html.read_html.at("h1").to_s.should == data
  end

  it "parses files" do
    data = {"hello"=>"there"}

    f = Path["/tmp/something.json"]
    f.write_json(data)
    f.parse.should == data
  end

  it "makes paths THREE WAYS!" do
    [
      Path(__FILE__),
      Path[__FILE__],
      Path.new(__FILE__),
    ].all_pairs do |p1, p2|
      p1.path.should == p2.path
    end
  end

  it "appending to paths with /" do
    ( Path['/etc']/'passwd' ).should == Path['/etc/passwd']
    ( Path['/etc']/Path['passwd'] ).should_not == Path['/etc/passwd']
  end

  it "lets you change the dirs array" do
    path = Path['/spam/spam/spam/']
    path.dirs.should == %w[ spam spam spam ]
    path.dirs << 'humbug'
    path.dir.should  == '/spam/spam/spam/humbug'
    path.path.should == '/spam/spam/spam/humbug/'
  end

  it "handles URLs" do
    path = Path["http://google.com/?search=blah"]
    path.host.should  == "google.com"
    path.port.should  == 80
    path.query.should == {"search" => "blah"}
    path.uri?.should  == true
  end

  it "tempfiles" do
    path = Path.tmpfile
    path.exists?.should == true

    path.write "blah"
    path.read.should == "blah"

    path.delete!
    path.exists?.should == false
  end

  it "appends and writes" do
    path = Path.tmpfile
    path.exists?.should == true

    path.write "blah"
    path.append "what"
    (path << "lul").should == path

    path.read.should == "blahwhatlul"

    path.write "rawr"

    path.read.should == "rawr"
  end

  it "cds into directories" do
    path = Path["/etc"]
    start = Path.pwd
    path.should_not == Path.pwd
    path.cd { path.should == Path.pwd }
    Path.pwd.should == start
  end

  it "renames/mvs" do
    path = Path.tmp

    path.rm
    path.touch

    path.exists?.should == true

    old_name = path.to_s

    dest = path.rename(:ext=>".dat")

    dest.to_s.should == old_name+".dat"
    path.to_s.should == old_name
    dest.to_s.should_not == old_name

    dest.exists?.should == true
    path.exists?.should == false

    path.touch
    lambda { path.rename(:ext=>".dat") }.should raise_error

    dest.rm
    path.rename!(:ext=>".dat")
    path.to_s.should_not == old_name
    path.exists?.should == true

    path.rm
  end

  it "backups" do
    path = Path.tmp
    path.rm
    path.touch

    dest = path.backup!
    path.exists?.should == false
    dest.exists?.should == true

    dest.rm

    path.touch
    # p path.numbered_backup_file

    dest = path.numbered_backup!
    path.touch
    dest2 = path.numbered_backup!

    dest.should_not == dest2
    path.should_not == dest

    dest.rm
    dest2.rm


    path = Path.tmpdir
    path.dir?.should == true
    backup = path.numbered_backup!
    backup.dir?.should == true
    backup.dirs.last.should == "#{path.dirs.last} (1)"
    backup.rm
  end

  it "rms" do
    path = Path.tmpfile
    path << "data"
    path.exists?.should == true
    path.rm.should      == true
    path.exists?.should == false
  end

  it "truncates" do
    tmp = Path.tmp
    tmp.rm
    tmp.touch

    tmp.exists?.should == true

    tmp.write("1"*100)
    tmp.size.should == 100

    tmp.truncate(50)
    tmp.size.should == 50

    tmp.truncate
    tmp.size.should == 0
  end

  it "checksums" do
    a, b = Path["**/*.rb"].take(2)
    [:sha1, :sha2, :md5].each do |meth|
      sum1 = a.send(meth)
      sum2 = b.send(meth)
      sum1.should_not == sum2
      sum1.size.should > 5
      sum1.should =~ /[a-z0-9]/
      sum2.should =~ /[a-z0-9]/
    end
  end

  it "mkdirs" do
    tmp = Path.tmpfile
    lambda { tmp.mkdir }.should raise_error
    tmp.rm
    tmp.mkdir.should be_truthy
    tmp.rm.should be_truthy

    tmp2 = Path.tmpfile
    tmp2.rm
    tmp2 = tmp2/"nonexistent"/"directory"

    tmp2.exists?.should == false
    lambda { tmp2.mkdir_p }.should_not raise_error
  end

  it "has classmethods" do
    path = Path.tmpfile

    path << "whee"*100
    path.sha1.should == Path.sha1(path)
  end

  it "gzips and gunzips" do
    tmp = Path.tmp

    data = ""
    500.times { data << "whee" }

    tmp.write data

    tmp.size.should == data.size

    tmp.ext.should_not == "gz"

    before = tmp.size
    tmp.gzip!
    after = tmp.size

    before.should > after
    tmp.ext.should == "gz"

    tmp.gunzip!
    tmp.size.should == before
  end

  it "exts" do
    path = Path["file.tar.gz"]
    path.ext.should == "gz"
    path.exts.should == ["tar", "gz"]
  end

  it "ios and streams" do
    path = Path.tmpfile
    f = open(path)
    f.inspect.should == path.io.inspect
    f.inspect.should == path.stream.inspect
  end

  it "mimes" do
    Path[__FILE__].mimetype.should == "application/x-ruby"
  end

  it "magic types" do
    Path[__FILE__].type.should == "rb"
  end

  it "whiches" do
    Path.which("ruby").should_not be_nil
    Path.which("asdfasdfhkajlsdhfkljashdf").should be_nil
    Path.which("ruby").class.should == Path

    testprogs = ["ps", "sh", "tar"]

    real_result = `which #{testprogs.join(" ")}`.each_line.map(&:strip)

    Path.which(*testprogs).map(&:path).should == real_result
  end

  it "Path[]s another path" do
    path = Path.tmpfile
    Path[path].path.should == path.path
  end

  it "uses advanced glob features" do
    #  ruby-1.9.2-p180 :001 > Path["~/.ssh/id_{dsa,rsa}.pub"]
    #  => /home/epi/.ssh/id_{dsa,rsa}.pub
    #  ruby-1.9.2-p180 :002 > Dir["~/.ssh/id_{dsa,rsa}.pub"]
    #  => []
    #  ruby-1.9.2-p180 :003 > Dir["../../.ssh/id_{dsa,rsa}.pub"]
    #  => ["../../.ssh/id_rsairb.pub"]

    Path["~/.ssh/id_{dsa,rsa}.pub"].size.should > 0
  end

  it "modes" do
    Path.tmpfile.mode.class.should == Fixnum
  end

  it "chmods and chmod_Rs" do
    tmp = Path.tmpfile
    tmp2 = Path.tmpfile
    tmp.touch
    tmp2.touch

    tmp.mode.should == tmp2.mode

    tmp.chmod("+x")
    system("chmod", "+x", tmp2)
    tmp.mode.should == tmp2.mode
  end

  it "siblingses" do
    sibs = Path.tempfile.siblings
    sibs.is_an?(Array).should == true
    sibs.include?(self).should == false
  end

  it 'path/".."s shows parent dir of file' do
    # path/
    tmp = Path.tmpfile
    tmp.rm if tmp.exists?
    tmp.mkdir

    #tmp.to_s.endswith('/').should == true
    file = tmp/"file"
    file.touch

    file.dirs.should == tmp.dirs
    file.filename.should_not == tmp.filename
  end

  it 'parents and childs properly' do
    root    = Path["/"]
    parent  = Path["/blah/stuff"]
    child   = Path["/blah/stuff/what"]
    neither = Path["/whee/yay"]

    # Table of parent=>child relationships
    {
      parent => child,
      root   => parent,
      root   => child,
      root   => neither,
    }.each do |parent, child|
      parent.should be_parent_of child
      child.should_not be_parent_of parent

      child.should be_child_of parent
      parent.should_not be_child_of child
    end

    neither.parent_of?(child).should == false
    neither.parent_of?(parent).should == false
  end

  it "checks file modes" do
    path = Path.tmpfile
    path.exe?.should == false
    path.chmod(0o666)

    (path.mode & 0o666).should > 0
  end

  it 'symlinks files' do
    path = Path.tmpfile
    path << "some data"

    target = "#{path}-symlinked"

    path.ln_s target

    target = Path[target]
    target.symlink?.should == true
    target.read.should == path.read
    target.symlink_target.should == path
  end

  it 'symlinks relative dirs' do
    tmpdir = Path.tmpdir

    symlink = (tmpdir/"a_new_link")
    Path["../../etc/passwd"].ln_s symlink

    symlink.symlink?.should == true

    symlink.rm
    tmpdir.rm
  end

  it 'swaps two files' do
    # swap two regular files


    # swap a symlink and a regular file
    # swap two symlinks
  end

  it 'realpaths' do
    etc = Path["/etc"]
    tmp = Path.tmpfile
    tmp.rm
    etc.ln_s tmp

    tmp.symlink_target.should == etc
    tmp.realpath.should == etc
    Path["/etc/../etc"].realpath.should == etc
  end

  it "shouldn't glob with Path#join" do
    path = Path["/etc"].join("blah{}")
    path.path.should == "/etc/blah{}"
  end

  it "should glob with Path#/" do
    entries = Path["/etc"]/"*"
    entries.should be_an Array
  end

  it "xattrs" do

    file = Path["~/test"]
    file.touch
    file["nothing"].should == nil

    file["user.test"] = "whee"

    file["user.test"].should == "whee"
    Path.getfattr(file)["user.test"].should == "whee"

    file["user.test"] = nil
    file["user.test"].should == nil
    Path.getfattr(file)["user.test"].should == nil

    lambda { file["blahblahblah"] = "whee" }.should raise_error

    # Test assigning an entire hash of attributes, using diffing
    attrs = file.attrs
    attrs["user.diff_element"] = "newtest"
    file.attrs = attrs
    file["user.diff_element"].should == "newtest"

    file["user.null-terminated-string"] = "stuff\u0000"
    file["user.null-terminated-string"].should == "stuff"
  end

  it "changes mtime/atime" do
    file   = Path.tmp
    now    = file.mtime
    before = now - 50.days

    file.mtime = before
    file.mtime.should == before

    beforebefore = before - 50.days

    file.atime = beforebefore
    file.atime.should == beforebefore
  end

  it "each_chunks" do
    path = Path["/etc/passwd"]
    path.each_chunk(20) { |chunk| chunk.size.should == 20; break }
  end

  it "cp_p's" do
    # raises an exception if one of the path components is an existing file (mkdir_p will fail!)
    # if the source is a directory, copies it recursively
    # if the source is a file, copies it and builds the directory tree
  end

end
