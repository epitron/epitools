require 'epitools/permutations'

describe "Permutations" do
  
  it "a * b" do
    ([1,2] * [3,4]).should == [ [1,3], [1,4], [2,3], [2,4] ]
  end    

  it "a**2" do
    ([1,2] ** 2).should == [ [1,1], [1,2], [2,1], [2,2] ]
  end    
  
end

