require 'epitools/clitools'

describe String do

  it "highlights" do
    color = :light_yellow
    highlighted = "xxx#{"match".send(color)}zzz"

    "xxxmatchzzz".highlight(/match/, color).should   == highlighted
    "xxxmatchzzz".highlight("match", color).should   == highlighted
    "xxxmatchzzz".highlight(/m.+h/, color).should    == highlighted
    "xxxmatchzzz".highlight(/MATCH/i, color).should  == highlighted
  end

  it "highlights with a block" do
    result = "xxxmatchxxx".highlight(/match/) { |match| "<8>#{match}</8>" }
    result.should == "xxx<8>match</8>xxx"
  end
  
  it "cmds" do
    cmd( ['test -f ?', __FILE__] ).should == true
    cmd( ['test -d ?', __FILE__] ).should == false
    cmd( "test", "-f", __FILE__ ).should == true 
    cmd( "test", "-d", __FILE__ ).should == false
    
    lambda { cmd( ["test -f ? ?", __FILE__] ) }.should raise_error  # too many ?'s
    lambda { cmd( ["test -f", __FILE__] ) }.should raise_error      # too few ?'s
  end
    
end
