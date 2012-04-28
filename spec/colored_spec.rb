require 'epitools'

describe "Colored strings" do
  
  it "has string methods" do
    s = "string"
    s.should respond_to(:blue)
    s.should respond_to(:light_blue)
    s.should respond_to(:bright_blue)
    s.should respond_to(:grey)
    s.should respond_to(:gray)
    s.should respond_to(:purple)
    s.should respond_to(:magenta)
    lambda { s.light_blue }.should_not raise_error
  end    
  
  it "can do bbs colors" do
    "<5>yay".colorize.should == "yay".magenta
  end
  
  it "can do tagged colors" do
    "<blue>hello".colorize.should == "hello".blue
    "<magenta>hello".colorize.should == "<purple>hello".colorize
    "<gray>hello".colorize.should == "<light_black>hello".colorize
    lambda { "</blue>".colorize }.should raise_error
    "<black_on_yellow>hello".colorize.should == "hello".black_on_yellow
  end
  
end

