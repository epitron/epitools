require 'epitools/fraction'

describe Fraction do

#  before :each do
#    @a = Fraction[1,1]
#    @b = Fraction[1,2]
#  end

  it "adds normally" do
    ( Fraction[1,1] + Fraction[1,2] ).should == Fraction[3,2]
  end

  it "doesn't let you add weird stuff together" do
    -> { Fraction[1,2] + :splunge }.should raise_error(TypeError)
  end

  it "timeses normally" do
    ( Fraction[1,1] * 2 ).should == Fraction[2,2]
    ( Fraction[1,2] * 2 ).should == Fraction[2,4]
    ( Fraction[1,1] * Fraction[1,2] ).should == Fraction[1,2]
    ( Fraction[5,3] * Fraction[1,2] ).should == Fraction[5*1, 2*3]
    ( Fraction[5,3] * Fraction[1,2] ).should == Fraction[5, 6]
    ( Fraction[1,2] * Fraction[1,2] ).should == Fraction[1, 4]
  end

  it "doesn't let you times it with weird stuff" do
    -> { Fraction[1,2] * ([:ayeeee]*100) }.should raise_error(TypeError)
  end

  it "floats" do
    Fraction[1,1].to_f.should == 1.0
    Fraction[1,2].to_f.should == 0.5

    -> { Fraction[1,0].to_f }.should raise_error(ZeroDivisionError)
  end

  it "percents" do
    Fraction[1,1].percent.should == "100.0%"
    Fraction[1,2].percent.should == "50.0%"
  end

  it "simplifies" do
    Fraction[2,4].simplify.should == Fraction[1,2]
    Fraction[4,2].simplify.should == Fraction[2,1]
  end

  it "has a function-style wrapper! (for paren fans)" do
    Fraction(1,2).should == Fraction[1,2]
    Fraction(1,2).should == Fraction.new(1,2)
  end

end
