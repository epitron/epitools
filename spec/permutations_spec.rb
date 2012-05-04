#require 'epitools/core_ext'
#require 'epitools/permutations'
require 'epitools'
require 'epitools/permutations'

describe "Permutations" do
  
  it "a*b" do
    ([1,2] * [3,4]).should == [ [1,3], [1,4], [2,3], [2,4] ]
  end    

  it "a**2" do
    ([1,2] ** 2).should == [ [1,1], [1,2], [2,1], [2,2] ]
  end    
  
  it "all_pairses" do
    [1,2,3,4].all_pairs.to_a.should == [ 
      [1,2], 
      [1,3], 
      [1,4], 
      [2,3],
      [2,4],
      [3,4],
    ]

    # reflexive    
    [1,2,3].all_pairs(true).to_a.should == [
      [1,1],
      [1,2],
      [1,3],
      [2,2],
      [2,3],
      [3,3],
    ]
  end

end
