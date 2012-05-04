require 'epitools'

describe WM do
  
  it "works" do
    WM.windows.any?.should == true
    WM.processes.any?.should == true
    WM.desktops.any?.should == true
    
    #WM.current_desktop.is_a?(WM::Desktop).should == true
    WM.current_desktop.nil? == false
  end    
  
end

