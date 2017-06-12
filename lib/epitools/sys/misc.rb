module Sys

  #
  # Trap signals!
  #
  # usage: trap("EXIT", "HUP", "ETC", :ignore=>["VTALRM"]) { |signal| puts "Got #{signal}!" }
  # (Execute Signal.list to see what's available.)
  #
  # No paramters defaults to all signals except VTALRM, CHLD, CLD, and EXIT.
  #
  def self.trap(*args, &block)
    options = if args.last.is_a?(Hash) then args.pop else Hash.new end
    args = [args].flatten
    signals = if args.any? then args else Signal.list.keys end

    ignore = %w[ VTALRM CHLD CLD EXIT ] unless ignore = options[:ignore]
    ignore = [ignore] unless ignore.is_a? Array

    signals = signals - ignore

    signals.each do |signal|
      p [:sig, signal]
      Signal.trap(signal) { yield signal }
    end
  end

  #-----------------------------------------------------------------------------

  cross_platform_method :browser_open

  #
  # Linux: Open an URL in the default browser (using "xdg-open").
  #
  def browser_open_linux(url)
    system("xdg-open", url)
  end

  #
  # Darwin: Open the webpage in a new chrome tab.
  #
  def browser_open_darwin(url)
    system("open", "-a", "chrome", url)
  end

  #-----------------------------------------------------------------------------

  def self.temperatures
    #/Applications/Utilities/TemperatureMonitor.app/Contents/MacOS/tempmonitor -a -l
    #CPU Core 1: 28 C
    #CPU Core 2: 28 C
    #SMART Disk Hitachi HTS543216L9SA02 (090831FBE200VCGH3D5F): 40 C
    #SMC CPU A DIODE: 41 C
    #SMC CPU A HEAT SINK: 42 C
    #SMC DRIVE BAY 1: 41 C
    #SMC NORTHBRIDGE POS 1: 46 C
    #SMC WLAN CARD: 45 C
    raise NotImplementedError.new("Sorry")
  end

end
