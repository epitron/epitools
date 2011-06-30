require 'epitools'

describe Path do
  
  it "initializes and accesses everything" do
    path = Path.new("/blah/what.mp4/.mp3/hello.avi")
    
    path.dirs.should == %w[ blah what.mp4 .mp3 ]
    path.dir.should == "/blah/what.mp4/.mp3"
    path.filename.should == "hello.avi"
    path.ext.should == "avi"
    path.base.should == "hello"
  end
  
  it "works with relative paths" do
    path = Path.new("../hello.mp3/blah")
    
    path.filename.should == "blah"
    path.ext.should == nil
    
    abs_path = File.join(File.expand_path(".."), "hello.mp3")
    path.dir.should == abs_path 
  end
  
  it "handles directories" do
    path = Path.new("/etc/")
    
    path.dirs.should_not == nil
    path.dir.should == "/etc"
    path.filename.should == nil
  end
  
  it "replaces ext" do
    path = Path.new("/blah/what.mp4/.mp3/hello.avi")
    
    path.ext.should == "avi"
    path.ext = "mkv"
    path.ext.should == "mkv"
    
    path.filename[-4..-1].should == ".mkv"
  end

  it "replaces filename" do
    path = Path.new(__FILE__)
    path.dir?.should == false
    path.filename = nil
    path.dir?.should == true
  end
  
  it "fstats" do
    path = Path.new(__FILE__)
    
    path.exists?.should == true
    path.dir?.should == false
    path.file?.should == true
    path.symlink?.should == false
    path.mtime.class.should == Time
  end
  
  it "globs" do
    path = Path.new(__FILE__)
    glob = path.dir + "/*spec.rb"
    specs = Path.glob(glob)
    path.in?(specs).should == true
  end
  
  it "Path[file] and Path[glob]s" do
    path = Path.new(__FILE__)
    path.should == Path[__FILE__]

    glob = path.dir + "/*spec.rb"
    specs = Path.glob(glob)
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
    path.dir.should == '/spam/spam/spam/humbug'
    path.path.should == '/spam/spam/spam/humbug/'
  end
  
  it "handles URLs" do
    path = Path["http://google.com/?search=blah"]
    path.host.should == "google.com"
    path.query.should == {"search" => "blah"}
    path.uri?.should == true
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
    path << "lul"
    
    path.read.should == "blahwhatlul"
    
    path.write "rawr"
    
    path.read.should == "rawr"
  end
  
  it "renames" do
    path = Path.tmpfile
    
    str = path.to_s
    
    path.rename(:ext=>".dat")
    
    path.to_s.should_not == str 
    path.to_s.should == str+".dat"
  end
  
  it "rms" do
    path = Path.tmpfile
    path << "data"
    path.exists?.should == true
    path.rm.should == true
    path.exists?.should == false
  end
  
  it "truncates" do
    path = Path.tmpfile

    path << "1"*100
    path.size.should == 100

    path.truncate(50)
    path.size.should == 50

    path.truncate
    path.size.should == 0
  end
  
  it "checksums" do
    a, b = Path["*.rb"].take(2)
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
    tmp.mkdir.should == true
    tmp.rm.should == true
  end
  
  it "has classmethods" do
    path = Path.tmpfile
    
    path << "whee"*100
    path.sha1.should == Path.sha1(path)
  end
  
  it "gzips and gunzips" do
    path = Path.tmpfile
    500.times { path << "whee" }
    
    path.ext.should_not == "gz"
    gzipped = path.gzip
    
    before = path.size
    after = gzipped.size
    before.should > after
    gzipped.ext.should == "gz"
    
    gunzipped = gzipped.gunzip
    gunzipped.size.should == before
    gunzipped.should == path
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
  
end
