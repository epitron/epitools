require 'epitools/minimal'
require 'epitools/clitools'

describe Object do

  # it "'highlight's" do
  #   color = :light_yellow
  #   highlighted = "xxx#{"match".send(color)}zzz"

  #   "xxxmatchzzz".highlight(/match/, color).should   == highlighted
  #   "xxxmatchzzz".highlight("match", color).should   == highlighted
  #   "xxxmatchzzz".highlight(/m.+h/, color).should    == highlighted
  #   "xxxmatchzzz".highlight(/MATCH/i, color).should  == highlighted
  # end

  # it "'highlight's with a block" do
  #   result = "xxxmatchxxx".highlight(/match/) { |match| "<8>#{match}</8>" }
  #   result.should == "xxx<8>match</8>xxx"
  # end

  it "'cmd's" do
    cmd( ['test -f ?', __FILE__] ).should == true
    cmd( ['test -d ?', __FILE__] ).should == false
    cmd( "test", "-f", __FILE__ ).should == true
    cmd( "test", "-d", __FILE__ ).should == false

    -> { cmd( ["test -f ? ?", __FILE__] ) }.should raise_error(TypeError) # more ?'s than args
    -> { cmd( ["test -f", __FILE__] ) }.should raise_error(RuntimeError)  # more args than ?'s
  end

  it "'which'es" do
    which("totally nonexistant", "probably nonexistant", "ls", "df").should_not == nil
    which("totally nonexistant", "probably nonexistant").should == nil
    which("ls", "df").should =~ /\/ls$/
  end

  it "'geoip's" do
    geoip("128.100.100.128").country_name.should == "Canada"

    -> { geoip("butt"*20) }.should raise_error(SocketError)

    $geoip = nil
    -> { geoip("8.8.4.4", nil, nil) }.should raise_error(RuntimeError)
  end


  it "notifies" do
    notify_send("butt", "hello i am a butt\nbuttbuttbutt")
  end

end
