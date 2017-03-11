require 'epitools/core_ext/array'

describe "Array#histogram" do

  it "does 1..10" do
    nums = (1..10).to_a
    nums.histogram(2).should == [ 5, 5 ]
    nums.histogram(5).should == [ 2, 2, 2, 2, 2 ]
  end

  it "does -10..10" do
    nums = (-9..10).to_a
    nums.histogram(2).should == [ 10, 10 ]
  end

  it "does floats" do
    nums = [0.12, 1.0, 2.2, 3.5, 4.7, 5.9, 6.6, 7.777, 8.898]
    nums.histogram(3).should == [3,3,3]
  end

  it "does ranges" do
    nums = (0..9).to_a
    nums.histogram(2, ranges: true).should == {
      0.0...4.5 => 5,
      4.5...9.0 => 5
    }
  end

end
