require 'rbtree'

describe RBTree do

  before :each do
    @t = RBTree.new
    @alphabet = [*'a'..'z'] 
    @alphabet.shuffle.each { |c| @t[c] = c.ord }
  end

  it "sizes" do
    @t.size.should == 26
  end

  it "eaches" do
    visited_keys = []

    @t.each do |k,v|
      k.ord.should == v
      visited_keys << k
    end

    visited_keys.should == @alphabet
  end
end
