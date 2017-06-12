module Sys

  #
  # Get an array of mounted filesystems (as fancy objects)
  #
  def self.mounts
    if linux?
      IO.popen(["findmnt", "--raw"]) { |io| io.drop(1).map { |line| Mount.new line } }
    else
      raise NotImplementedError.new("I dunno, how do you find mounts on #{os}?")
    end
  end


  class Mount
    attr_accessor :dev, :type, :options

    def initialize(line)
      @path, @dev, @type, @options = line.strip.split(' ')
      @options = @options.split(",")
    end

    def system?
      (path =~ %r{^/(sys|dev|proc|run/user|tmp)}) or dev == "systemd-1"
    end

    def inspect
      "#{type}: #{path} (#{dev})"
    end

    def to_s
      "#{path} (#{dev})"
    end

    def path
      # Unescape findmnt's hex codes
      Path.new "#{eval %{"#{@path}"}}/"
    end

    def dirname
      path.dirs.last
    end
  end

end