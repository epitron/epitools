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

  it "compact syntaxes" do
    t = TypedStruct["a,b:int c,d:bool"].new(1,2,1,0)
    t.a.should == 1
    t.b.should == 2
    t.c.should == true
    t.d.should == false
  end

  it "wildcardses" do
    t = TypedStruct["a:int *"].new

                 t.a.should == nil
    t.a = "111"; t.a.should == 111

                 t.q.should == nil
    t.q = "111"; t.q.should == "111"
  end

  it "drops unknowns" do

    ts = TypedStruct["a:int"]
    lambda { ts.new a: 1, b: 2 }.should raise_error

    ts = TypedStruct["a:int -"]
    lambda {
      t = ts.new a: 1, b: 2
      t.a.should == 1
      lambda { t.b }.should raise_error
    }.should_not raise_error
  end

  it "can't use wildcard and drop unknown at once" do
    lambda { TypedStruct["a:int - *"].new }.should raise_error
  end

end

