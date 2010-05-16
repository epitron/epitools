require 'epitools/zopen'
require 'tempfile'

describe "zopen()" do
  
  before :all do
    @data = ("x"*100+"\n") * 1000
    @tmp = Tempfile.new("zopen_spec")
    
    @plainfile = @tmp.path
    @gzfile    = "#{@tmp.path}.gz" 
  end
  
  after :all do
    File.unlink @plainfile
    File.unlink @gzfile
  end
  
  it "writes/reads a gz" do
    f = zopen(@gzfile, "w")
    f.write(@data).should == @data.size
    f.close
    
    f = zopen(@gzfile, "r")
    f.read.should == @data
    f.close
  end

  it "writes/reads non-gz files" do
    zopen(@plainfile, "w") {|f| f.write(@data) }
    
    # readstyle
    File.read(@plainfile).should == zopen(@plainfile).read
    
    # blockstyle
    open(@plainfile){|f| f.read }.should == zopen(@plainfile){|f| f.read }
  end
  
  it "is enumerable" do
    zopen(@gzfile) do |f|
      f.respond_to?(:each).should == true
      f.respond_to?(:map).should == true
      f.respond_to?(:inject).should == true
      
      f.all?{|line| line =~ /^x+$/ }
    end    
  end

end
