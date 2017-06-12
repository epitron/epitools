module Sys

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
  # BSD: Return a hash of (device, IP address) pairs.
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

  #
  # Darwin: Do whatever BSD does
  #
  def self.interfaces_darwin
    interfaces_bsd
  end

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

end