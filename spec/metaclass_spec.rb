require 'epitools/metaclass'

describe "Metaclass" do
  
  it "works!" do
    o = Object.new
    metaclass = class << o; self; end
    o.metaclass.should == metaclass
  end    
  
end

