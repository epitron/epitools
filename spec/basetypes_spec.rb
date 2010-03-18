require 'epitools/basetypes'

describe Object do
  
  it "in?" do
    5.in?([1,2,3,4,5,6]).should == true
    5.in?(1..10).should == true
    5.in?(20..30).should == false
    "butt".in?("butts!!!").should == true
  end    
  
end

describe Integer do
  
  it "integer?" do
    
    {
      nil => false,
      "123" => true,
      "000" => true,
      123 => true,
      123.45 => true,
      "123asdf" => false,
      "asdfasdf" => false,
      Object.new => false,
      
    }.each do |object, expected_result|
      object.integer?.should == expected_result
    end
    
  end
  
end


describe Array do
  
  it "recursively maps" do
    [[1,2],[3,4]].recursive_map {|e| e ** 2}.should == [[1,4],[9,16]] 
    [1,2,3,4].recursive_map {|e| e ** 2}.should == [1,4,9,16] 
    [[],[],1,2,3,4].recursive_map {|e| e ** 2}.should == [[], [], 1, 4, 9, 16] 
  end
  
  it "squashes" do
    [1,2,[3,4,[5],[],[nil,nil],[6]]].squash.should == [1,2,3,4,5,6]
  end
  
end


describe Integer do
  
  it "has bits" do
    1.to_bits.should == [1]
    2.to_bits.should == [0,1]
    3.to_bits.should == [1,1]
    42.to_bits.should == [0,1,0,1,0,1]
  end
  
end


describe Enumerable do

  it "splits" do
    [1,2,3,4,5].split_at{|e| e == 3}.should          == [[1,2],[4,5]]
    [1,2,3,4,5].split_after{|e| e == 3}.should    == [[1,2,3],[4,5]]
    [1,2,3,4,5].split_before{|e| e == 3}.should   == [[1,2],[3,4,5]]

    "a\nb\n---\nc\nd\n".split_at(/---/).map_recursive(&:strip).should   == [ %w[a b], %w[c d] ]
  end
  
end


