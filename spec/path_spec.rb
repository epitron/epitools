require 'epitools/permutations'
require 'epitools/path'

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
    
    path.ext = "mkv"
    path.ext.should == "mkv"
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
    p [:path, path]
    path.host.should == "google.com"
    path.query.should == {"search" => "blah"}
    path.uri?.should == true
  end
  
end
