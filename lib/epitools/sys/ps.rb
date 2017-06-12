require_relative "os"

module Sys

  #
  # List all (or specified) processes, and return ProcessInfo objects.
  # (Takes an optional list of pids as arguments.)
  #
  def self.ps(*pids)
    raise "that's too many pids!" if pids.size > 999_999

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

  #-----------------------------------------------------------------------------

  def self.tree
    tree = Sys.ps.group_by(&:ppid)
    Hash[tree.map do |ppid, children|
      kvs = children.map { |child| [child.pid, tree.delete(child.pid)] }
      [ppid, Hash[kvs]]
    end]
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

end