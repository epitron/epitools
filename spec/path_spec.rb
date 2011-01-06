require 'epitools/path'

describe Path do
  
  it "initializes and accesses everything" do
    path = Path.new("/blah/what.mp4/.mp3/hello.avi")
    
    path.dirs.should == %w[ blah what.mp4 .mp3 ]
    path.dir.should == "/blah/what.mp4/.mp3"
    path.filename.should == "hello.avi"
    path.ext.should == ".avi"
    path.base.should == "hello"
  end
  
  it "works with relative paths" do
    path = Path.new("../hello.mp3/blah")
    
    path.filename.should == "blah"
    path.ext.should == nil
    
    abs_path = File.join(File.absolute_path(".."), "hello.mp3")
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
    
    path.ext.should == ".avi"
    path.ext = ".mkv"
    path.ext.should == ".mkv"
    
    path.ext = "mkv"
    path.ext.should == ".mkv"
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
  
end
