require 'epitools/basetypes'


describe Object do
  
  it "in?" do
    5.in?([1,2,3,4,5,6]).should == true
    5.in?(1..10).should == true
    5.in?(20..30).should == false
    "butt".in?("butts!!!").should == true
  end
  
  it "benches" do
    lambda { 
      bench("benchmark test") { x = 10 }
    }.should_not raise_error

    lambda { 
      bench("benchmark test") { raise "ERROR" }
    }.should raise_error
  end

  it "trys" do
    s = Struct.new(:a,:b).new
    s.a = 5
    s.b = 10
    
    s.try(:a).should == 5 
    s.try(:b).should == 10
    s.try(:c).should == nil
    
    lambda { s.try(:c) }.should_not raise_error
    lambda { s.c }.should raise_error

    def s.test(a); a; end
    
    s.test(1).should == 1
    s.try(:test, 1).should == 1
    
    lambda { s.test }.should raise_error
    lambda { s.try(:test) }.should raise_error
    
    def s.blocky; yield; end

    s.blocky{ 1 }.should == 1
    s.try(:blocky){ 1 }.should == 1
    s.try(:nonexistant){ 1 }.should == nil
  end
  
  it "nots" do
    10.even?.should == true
    10.not.even?.should == false
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
  
  it "has bits" do
    1.to_bits.should == [1]
    2.to_bits.should == [0,1]
    3.to_bits.should == [1,1]
    42.to_bits.should == [0,1,0,1,0,1]
  end
  
end


describe Array do
  
  it "squashes" do
    [1,2,[3,4,[5],[],[nil,nil],[6]]].squash.should == [1,2,3,4,5,6]
  end
  
end


describe Enumerable do

  it "splits" do
    [1,2,3,4,5].split_at{|e| e == 3}.should          == [[1,2],[4,5]]
    [1,2,3,4,5].split_after{|e| e == 3}.should    == [[1,2,3],[4,5]]
    [1,2,3,4,5].split_before{|e| e == 3}.should   == [[1,2],[3,4,5]]

    "a\nb\n---\nc\nd\n".split_at(/---/).map_recursive(&:strip).should   == [ %w[a b], %w[c d] ]
  end

  it "handles nested things" do
    array = [ [],["a"],"a",[1,2,3] ]

    lambda { 
      array.split_at("a")
    }.should_not raise_error
    
    array.split_at("a").should     == [ array[0..1], array[3..3] ] 
    array.split_at([1,2,3]).should == [ array[0..2] ]
  end
  
  it "handles arbitrary objects" do
    arbitrary = Struct.new(:a, :b, :c)
    
    particular = arbitrary.new(1,2,3)
    array = [ arbitrary.new, arbitrary.new, particular, arbitrary.new]
    
    array.split_at(particular).should == [ array[0..1], array[3..3] ]    
  end
  
  it "sums" do
    [1,2,3,4,5].sum.should == 15
  end
  
  it "averages" do
    [1,3].average.should == 2.0
    [1,1,3,3].average.should == 2.0
  end

  it "recursively maps" do
    [[1,2],[3,4]].recursive_map {|e| e ** 2}.should == [[1,4],[9,16]] 
    [1,2,3,4].recursive_map {|e| e ** 2}.should == [1,4,9,16] 
    [[],[],1,2,3,4].recursive_map {|e| e ** 2}.should == [[], [], 1, 4, 9, 16] 
  end
  
  it "foldl's" do
    a = [1,2,3,4]
    a.foldl(:+).should == a.sum
    %w[hi there].foldl(:+).should == "hithere"
  end
  
end

describe Hash do

  before :each do
    @h = {"key1"=>"val1", "key2"=>"val2"}
  end
    
  it "maps keys" do
    h = @h.map_keys{|k| k.upcase}
    h.keys.should == @h.keys.map{|k| k.upcase}
    h.values.should == @h.values
    
    h.map_keys! { 1 }
    h.keys.should == [1]
  end
  
  it "maps values" do
    h = @h.map_values{|v| v.upcase}
    h.values.should == @h.values.map{|v| v.upcase}
    h.keys.should == @h.keys
    h.map_values!{ 1 }
    h.values.should == [1,1]
  end
  
end


describe BlankSlate do
  
  it "is blank!" do
    BlankSlate.methods(false).should == []
  end
  
end
  
