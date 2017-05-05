require 'epitools/minimal'

#
# Cross-platform operating system functions.
# Includes: process listing, platform detection, etc.
#
module Sys

  #-----------------------------------------------------------------------------
  #
  # List all (or specified) processes, and return ProcessInfo objects.
  # (Takes an optional list of pids as arguments.)
  #
  def self.ps(*pids)
    #return @@cache if @@cache

    options = PS_FIELDS.join(',')

    pids = pids.map(&:to_i)

    if pids.any?
      command = "ps -p #{pids.join(',')} -o #{options}"
    else
      command = "ps awx -o #{options}"
    end

    lines = `#{command}`.lines.to_a

    lines[1..-1].map do |line|
      fields = line.split
      if fields.size > PS_FIELDS.size
        fields = fields[0..PS_FIELDS.size-2] + [fields[PS_FIELDS.size-1..-1].join(" ")]
      end

      fields = PS_FIELDS.zip(fields).map { |name, value| value.send(PS_FIELD_TRANSFORMS[name]) }

      ProcessInfo.new(*fields)
    end
  end

  #
  # Return the current operating system: Darwin, Linux, or Windows.
  #
  def self.os
    return @os if @os

    require 'rbconfig'
    if defined? RbConfig
      host_os = RbConfig::CONFIG['host_os']
    else
      host_os = Config::CONFIG['host_os']
    end

    case host_os
      when /darwin/
        @os = "Darwin"
      when /bsd/
        @os = "BSD"
      when /linux/
        @os = "Linux"
      when /mingw|mswin|cygwin/
        @os = 'Windows'
    else
      #raise "Unknown OS: #{host_os.inspect}"
    end

    @os
  end

  #
  # Is this Linux?
  #
  def self.linux?
    os == "Linux"
  end

  #
  # Is this Windows?
  #
  def self.windows?
    os == "Windows"
  end

  #
  # Is this Darwin?
  #
  def self.darwin?
    os == "Darwin"
  end

  #
  # Is this a Mac? (aka. Darwin?)
  #
  def self.mac?; darwin?; end

  #
  # Is this BSD?
  #
  def self.bsd?
    os == "BSD" or os == "Darwin"
  end

  #-----------------------------------------------------------------------------

  PS_FIELD_TABLE = [
    [:pid,    :to_i],
    [:ppid,   :to_i],
    [:pcpu,   :to_f],
    [:pmem,   :to_f],
    [:stat,   :to_s],
    [:rss,    :to_i],
    [:vsz,    :to_i],
    [:user,   :to_s],
    [:majflt, :to_i],
    [:minflt, :to_i],
    [:command,:to_s],
  ]

  PS_FIELDS             = PS_FIELD_TABLE.map { |name, func| name }
  PS_FIELD_TRANSFORMS   = Hash[ *PS_FIELD_TABLE.flatten ]

  class ProcessNotFound < Exception; end

  #
  # Contains all the information that PS can report about a process for
  # the current platform.
  #
  # The following attribute accessor methods are available:
  #
  #    pid     (integer)
  #    command (string -- the 'ps' name)
  #    name    (alias for 'command')
  #    pcpu    (float)
  #    pmem    (float)
  #    stat    (string)
  #    rss     (integer)
  #    vsz     (integer)
  #    user    (string)
  #    majflt  (integer)
  #    minflt  (integer)
  #    state   (array of symbols; see DARWIN_STATES or LINUX_STATES)
  #
  # Only on linux:
  #    exename (string -- path to the binary)
  #    fds     (array -- list of open file descriptors)
  #
  class ProcessInfo < Struct.new(*PS_FIELDS+[:state])

    DARWIN_STATES = {
      "R"=>:running,
      "S"=>:sleeping,
      "I"=>:idle,
      "T"=>:stopped,
      "U"=>:wait,
      "Z"=>:zombie,
      "W"=>:swapped,

      "s"=>:session_leader,
      "X"=>:debugging,
      "E"=>:exiting,
      "<"=>:high_priority,
      "N"=>:low_priority,
      "+"=>:foreground,
      "L"=>:locked_pages,
    }

    LINUX_STATES = {
      "R"=>:running,
      "S"=>:sleeping,
      "T"=>:stopped,
      "D"=>:wait,
      "Z"=>:zombie,
      "W"=>:swapped,
      "X"=>:dead,

      "s"=>:session_leader,
      "<"=>:high_priority,
      "N"=>:low_priority,
      "+"=>:foreground,
      "L"=>:locked_pages,
      "l"=>:multithreaded,
    }

    def initialize(*args)
      @dead = false
      args << stat_to_state(args[PS_FIELDS.index(:stat)])
      super(*args)
    end

    def parent
      Sys.ps(ppid).first unless ppid < 1
    end

    def children
      @@parents ||= Sys.ps.group_by(&:ppid)
      @@parents[pid]
    end

    #
    # Convert all the process information to a hash.
    #
    def to_hash
      Hash[ *members.zip(values).flatten(1) ]
    end

    #
    # Send the TERM signal to this process.
    #
    def kill!(signal="TERM")
      puts "Killing #{pid} (#{signal})"
      Process.kill(signal, pid)
      # TODO: handle exception Errno::ESRCH (no such process)
    end

    #
    # Has this process been killed?
    #
    def dead?
      @dead ||= Sys.pid(pid).empty?
    end

    #
    # Refresh this process' statistics.
    #
    def refresh
      processes = Sys.ps(pid)

      if processes.empty?
        @dead = true
        raise ProcessNotFound
      end

      updated_process = processes.first
      members.each { |member| self[member] = updated_process[member] }
      self
    end

    alias_method :name, :command

    # Linux-specific methods
    if Sys.linux?

      def exename
        @exename ||= File.readlink("/proc/#{pid}/exe") rescue :unknown
        @exename == :unknown ? nil : @exename
      end

      def fds
        Dir["/proc/#{pid}/fd/*"].map { |fd| File.readlink(fd) rescue nil }
      end

    end

    private

    def stat_to_state(str)
      states = case Sys.os
        when "Linux"  then LINUX_STATES
        when "Darwin" then DARWIN_STATES
        else raise "Unsupported platform: #{Sys.os}"
      end

      str.scan(/./).map { |char| states[char] }.compact
    end
  end

  #-----------------------------------------------------------------------------

  def self.tree
    tree = Sys.ps.group_by(&:ppid)
    Hash[tree.map do |ppid, children|
      kvs = children.map { |child| [child.pid, tree.delete(child.pid)] }
      [ppid, Hash[kvs]]
    end]
  end

  #-----------------------------------------------------------------------------

  def self.refresh
    @@cache = nil
  end

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

  #
  # A metaprogramming helper that allows you to write platform-specific methods
  # which the user can call with one name. Here's how to use it:
  #
  # Define these methods:
  #   reboot_linux, reboot_darwin, reboot_windows
  #
  # Call the magic method:
  #   cross_platform_method(:reboot)
  #
  # Now the user can execute "reboot" on any platform!
  #
  # (Note: If you didn't create a method for a specific platform, then you'll get
  # NoMethodError exception when the "reboot" method is called on that platform.)
  #
  def self.cross_platform_method(name)
    platform_method_name = "#{name}_#{os.downcase}"
    metaclass.instance_eval do
      define_method(name) do |*args|
        begin
          self.send(platform_method_name, *args)
        rescue NoMethodError
          raise NotImplementedError.new("#{name} is not yet supported on #{os}.")
        end
      end
    end
  end

  #-----------------------------------------------------------------------------

  cross_platform_method :hostname

  def self.hostname_linux
    `uname -n`.strip
  end

  def self.hostname_mac
    `uname -n`.strip.gsub(/\.local$/, '')
  end

  def self.hostname_windows
    raise NotImplementedError
  end

  #-----------------------------------------------------------------------------

  cross_platform_method :interfaces

  #
  # Darwin: Return a hash of (device, IP address) pairs.
  #
  # eg: {"en0"=>"192.168.1.101"}
  #
  def self.interfaces_bsd
    sections = `ifconfig`.split(/^(?=[^\t])/)
    sections_with_relevant_ip = sections.select {|i| i =~ /inet/ }

    device_ips = {}
    sections_with_relevant_ip.each do |section|
      device  = section[/[^:]+/]
      ip      = section[/inet ([^ ]+)/, 1]
      device_ips[device] = ip
    end

    device_ips
  end

  def self.interfaces_darwin; interfaces_bsd; end

  #
  # Linux: Return a hash of (device, IP address) pairs.
  #
  # eg: {"eth0"=>"192.168.1.101"}
  #
  def self.interfaces_linux
    sections = `/sbin/ifconfig`.split(/^(?=Link encap:Ethernet)/)
    sections_with_relevant_ip = sections.select {|i| i =~ /inet/ }

    device_ips = {}
    sections_with_relevant_ip.each do |section|
      device  = section[/([\w\d]+)\s+Link encap:Ethernet/, 1]
      ip      = section[/inet addr:([^\s]+)/, 1]
      device_ips[device] = ip
    end

    device_ips
  end

  #
  # Windows: Return a hash of (device name, IP address) pairs.
  #
  def self.interfaces_windows
    result = {}
    `ipconfig`.split_before(/^\w.+:/).each do |chunk|
      chunk.grep(/^Ethernet adapter (.+):\s*$/) do
        name = $1
        chunk.grep(/IPv[46] Address[\.\ ]+: (.+)$/) do
          address = $1.strip
          result[name] = address
        end
      end
    end
    result
  end

  #-----------------------------------------------------------------------------

  cross_platform_method :browser_open

  #
  # Linux: Open an URL in the default browser (using "gnome-open").
  #
  def browser_open_linux(url)
    system("gnome-open", url)
  end

  #
  # Darwin: Open the webpage in a new chrome tab.
  #
  def browser_open_darwin(url)
    system("open", "-a", "chrome", url)
  end

  #-----------------------------------------------------------------------------

  cross_platform_method :memstat

  def self.memstat_linux
    #$ free
    #             total       used       free     shared    buffers     cached
    #Mem:       4124380    3388548     735832          0     561888     968004
    #-/+ buffers/cache:    1858656    2265724
    #Swap:      2104504     166724    1937780

    #$ vmstat
    raise "Not implemented"
  end

  def self.memstat_darwin
    #$ vm_stat
    #Mach Virtual Memory Statistics: (page size of 4096 bytes)
    #Pages free:                         198367.
    #Pages active:                       109319.
    #Pages inactive:                      61946.
    #Pages speculative:                   18674.
    #Pages wired down:                    70207.
    #"Translation faults":            158788687.
    #Pages copy-on-write:              17206973.
    #Pages zero filled:                54584525.
    #Pages reactivated:                    8768.
    #Pageins:                            176076.
    #Pageouts:                             3757.
    #Object cache: 16 hits of 255782 lookups (0% hit rate)

    #$ iostat
    raise "Not implemented"
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
    raise "Not implemented"
  end

end

if $0 == __FILE__
  require 'pp'
  procs = Sys.ps
  p [:processes, procs.size]
#  some = procs[0..3]
#  some.each{|ps| pp ps}
#  some.first.kill!
#  pp some.first.to_hash
#  p [:total_cpu, procs.map{|ps| ps.pcpu}.sum]
#  p [:total_mem, procs.map{|ps| ps.pmem}.sum]

  pp Sys.interfaces
end
