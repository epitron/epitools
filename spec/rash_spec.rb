require 'epitools'

describe Rash do

  attr_accessor :r
  
  before :each do
    @r = Rash.new(
      /hello/ => "hello",
      /world/ => "world",
      "other" => "whee",
      true    => false,
      1       => "awesome",
      1..1000 => "rangey",
      #/.+/ => "EVERYTHING"
    )
  end
  
  it "string lookups" do
    r["other"].should == "whee"
    r["well hello there"].should == "hello"
    r["the world is round"].should == "world"
    r.all("hello world").sort.should == ["hello", "world"]
  end

  it "regex lookups" do
    r[/other/].should == "whee"
  end

  it "other objects" do  
    r[true].should == false
    r[1].should == "awesome"
  end
  
  it "does ranges" do
    @r[250].should == "rangey"
    @r[999].should == "rangey"
    @r[1000].should == "rangey"
    @r[1001].should == nil
  end
  
  it "calls procs on matches when they're values" do
    r = Rash.new( /(ello)/ => proc { |m| m[1] } )
    r["hello"].should == "ello"
    r["ffffff"].should == nil
  end
  
end