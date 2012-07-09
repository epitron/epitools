require 'epitools'

describe WM do
  
  it "works" do
    WM.windows.any?.should == true
    WM.processes.any?.should == true
    WM.desktops.any?.should == true
    
    #WM.current_desktop.is_a?(WM::Desktop).should == true
    WM.current_desktop.nil? == false
  end    

  def to_events(keys)
  	WM::Window.new.keys_to_events(keys)
  end

  it "parses X keys-string" do
  	events = to_events "Hello<Ctrl-T><Ctrl-L><Return>!!!"
  	events.should == ["Shift<Key>H", "<Key>e", "<Key>l", "<Key>l", "<Key>o", "Ctrl<Key>t", "Ctrl<Key>l", "<Key>Return", "Shift<Key>0x21", "Shift<Key>0x21", "Shift<Key>0x21"]
  end

  it "handles something weird" do
  end

  it "sends keys to this window" do
	sublime_window = WM.current_desktop.windows.select{|w| w.title =~ /wm_spec\.rb.+Sublime/ }.first
	sublime_window.send_keys('<Ctrl-`>print "Hello from send_keys()!"<Return>')
  end
  
end

