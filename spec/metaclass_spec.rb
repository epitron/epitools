require 'epitools/metaclass'

describe "Metaclass" do
  
  it "metaclass" do
    o = Object.new
    o_metaclass = class << o; self; end
    o.metaclass.should == o_metaclass
  end    
  
end

