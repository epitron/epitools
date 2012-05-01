require 'epitools'

describe TypedStruct do
  
  it "works" do
    t = TypedStruct["a:int b c:boolean d:timestamp"].new

                 t.a.should == nil
    t.a = "111"; t.a.should == 111
    t.b = "111"; t.b.should == "111"
    t.c = "yes"; t.c.should == true
    #t.c?.should == true
  end    
  
end

