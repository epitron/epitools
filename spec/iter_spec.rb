require 'epitools/iter'

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
  
  it "cluters nearby elements" do
    class Cluster < Array
      def min_distance(other)
        a, b = other.max, other.min
        x, y = max, min
        [a-x, a-y, b-x, b-y].map(&:abs).min
      end
      
      def absorb(other)
        concat other
        sort!
        other.clear 
      end
    end
  
    a = [1,2,5,6,7,10,11,13].map { |e| Cluster.new [e] }
    i = Iter.new(a)
    
    i.each_cons(2) do |a,b|
      if b.any? and a.any? and a.min_distance(b) <= 1
        b.absorb(a)
        a.remove
      end
    end
    
    i.to_a.should == [[1,2],[5,6,7],[10,11],[13]]
  end
  
end