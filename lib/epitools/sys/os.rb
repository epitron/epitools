module Sys

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

end
