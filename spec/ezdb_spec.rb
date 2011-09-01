require 'epitools/ezdb'
require 'epitools/path'

class Test < Struct.new(:a, :b); end

describe Ezdb do

  attr_accessor :db

  before :each do
    @dbfile = Path["test.db"]
    @dbfile.rm if @dbfile.exists?
    @db = Ezdb.new @dbfile
  end
  
  after :each do
    @db.delete!
  end
  
  it "stores/retrieves" do
    db[1].should == nil
    db[1] = :blah
    db[1].should == :blah
    db.keys.should == [1]
    
    s = Test.new("what", true)
    db[s] = false
    db[s].should == false
  end
  
  it "handles nil extensions" do
    x = Ezdb.new "testdb"
    x[1].should == nil
    x.delete!
  end
  
  it "pushes" do
    db[:a] ||= []
    db[:a].should == []
    db[:a] << 1
    db[:a] << 2
    db[:a] << 3
    db[:a] << 4
    db[:a].should == [1,2,3,4]
  end
  
end