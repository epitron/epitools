require 'epitools'

describe Sys::ProcessInfo do

  specify "OS type" do
    proc { Sys.os }.should_not raise_error
    proc { Sys.linux? }.should_not raise_error
    proc { Sys.mac? }.should_not raise_error
    proc { Sys.darwin? }.should_not raise_error
    proc { Sys.bsd? }.should_not raise_error
    proc { Sys.windows? }.should_not raise_error

    %w[Linux Windows Darwin BSD].include?(Sys.os).should == true

    [:linux?, :mac?, :windows?, :bsd?].any? { |os| Sys.send(os) }.should == true
  end


  specify "list all processes" do
    # Sys.ps.should_not be_blank
    procs = Sys.ps

    procs.first.state.is_a?(Array).should == true

    pids = procs.map{ |process| process.pid }

    p2s = Hash[ *Sys.ps(*pids).map { |process| [process.pid, process] }.flatten ]
    matches = 0
    procs.each do |p1|
      if p2 = p2s[p1.pid]
        matches += 1
        p1.command.should == p2.command

        # FIXME: this behaves weirdly with kernel processes, eg:
        # expected: "[kworker/u8:1-phy5]"
        #      got: "[kworker/u8:1-events_unbound]" (using ==)

      end
    end

    matches.should > 1
  end

  specify "cross-platform methods" do
    Sys.cross_platform_method(:cross_platform_test)
    proc { Sys.cross_platform_test }.should raise_error(NotImplementedError)
  end

  specify "network interfaces" do
    Sys.interfaces.should_not be_blank
  end

  specify "mounts" do
    Sys.mounts.should_not be_blank
  end

end
