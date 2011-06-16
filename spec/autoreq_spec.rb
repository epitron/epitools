require 'epitools'

describe "autoreq" do

  it "should have MimeMagic and Units installed" do
    gems = Gem.source_index.to_a.map{|name, spec| spec.name}.uniq
    gems.include?("mimemagic").should == true
    gems.include?("units").should == true
  end

  it "autoreqs a gem" do
    defined?(MimeMagic).should == nil

    autoreq :MimeMagic, 'mimemagic'
    lambda { MimeMagic }.should_not raise_error
  end
    
  it "autoreqs a regular ruby file" do
    defined?(Net).should == nil
    
    module Net
      autoreq :HTTP, 'net/http'
    end
    lambda { Net::HTTP }.should_not raise_error
  end
    
  it "autoreqs a gem with a block" do
    defined?(Units).should == nil
    
    autoreq :Units do
      gem 'units', '~> 1.0'
      require 'units'
    end
    lambda { Units }.should_not raise_error
  end
    
end
