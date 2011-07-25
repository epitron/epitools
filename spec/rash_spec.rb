require 'epitools/rash'

describe Rash do

  attr_accessor :r
  
  before :each do
    @r = Rash.new(
      /hello/ => "hello",
      /world/ => "world",
      "other" => "whee",
      true    => false,
      1       => "awesome"
      #/.+/ => "EVERYTHING"
    )
  end
  
  it "string lookups" do
    r["other"].should == "whee"
    r["well hello there"].should == ["hello"]
    r["the world is round"].should == ["world"]
    r["hello world"].sort.should == ["hello", "world"]
  end

  it "regex lookups" do
    r[/other/].should == ["whee"]
  end

  it "other objects" do  
    r[true].should == false
    r[1].should == "awesome"
  end

end