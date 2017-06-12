module Sys

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

end