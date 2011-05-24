require 'epitools/ratio'

describe Ratio do
  
  before :each do
    @a = Ratio[1,1]
    @b = Ratio[1,2]
  end

  it "adds" do
    ( @a + @b ).should == Ratio[2,3]
  end
  
  it "floats" do
    @a.to_f.should == 1.0
    @b.to_f.should == 0.5
  end
  
  it "percents" do
    @a.percent.should == "100.0%"
    @b.percent.should == "50.0%"
  end

  it "uses the function-style wrapper" do
    Ratio(1,2).should == Ratio[1,2]
    Ratio(1,2).should == Ratio.new(1,2)
  end
  
end