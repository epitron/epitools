require 'epitools/iter'
require 'pry'

describe Iter do

  before :each do
    @i = Iter.new([1,2,3,4,5])
  end

  it "iterates" do
    @i.iterate(2) do |i,j|
      i.should_not == j
    end
  end
  
  it "to_a's" do
    @i.to_a.should == [1,2,3,4,5]
  end
  

  it "reverses" do
    @i.iterate(2) do |a, b|
      b.move_before(a)
    end
    
    @i.to_a.should == [5,4,3,2,1]
  end

  it "next/prevs" do
    @i.iterate(2) do |a,b|
      a.next.should == b
      b.prev.should == a
    end
  end
  
  it "removes" do
    @i.iterate {|x| x.remove if x % 2 == 1 }
    @i.to_a.should == [2,4]    
  end
  
  it "replaces" do
    @i.first.replace_with(-1)
    @i.to_a.should == [-1,2,3,4,5]    
    @i.last.replace_with(8)
    @i.to_a.should == [-1,2,3,4,8]
  end
  
  it "slices, values, indexes, etc." do
    # todo: slice should return an iter
    @i.first.should == 1
    @i[0..1].should == @i.values_at(0,1) 
    @i[0..-1].should == @i 
    @i[-1].should == @i.last
    @i[-2..-1].should == @i.values_at(-2,-1)
  end
  
  it "move_first/last" do
    @i.first.move_last
    @i.to_a.should == [2,3,4,5,1]
    
    @i.last.move_first
    @i.should == [1,2,3,4,5]
  end
  
  it "sorts an array" do
    i = Iter.new [3,7,3,1,3]
    i.each { |a|
      
    }
  end  
end