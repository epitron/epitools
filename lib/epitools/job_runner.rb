#
# Runs many jobs in parallel, and returns their interleaved results.
# (NOTE: The JobRunner can be run multiple times; each time the blocks
#  will be executed again.)
#
# Examples:
#
# JobRunner.new do |jr|
#   jr.add { 3 }
#   jr.add { sleep 0.1; 2 }
#   jr.add { sleep 0.2; 1 }
#
#   jr.each_result do |result|
#     p result
#   end
# end
#
# jr = JobRunner.new(
#   proc { 1 },
#   proc { 2 },
#   proc { 3 }
# )
#
# 2.times do
#   jr.each_result { |result| p result }
# end
#
class JobRunner
  def initialize(*blocks, debug: false)
    @threads = []
    @results = Thread::Queue.new
    @jobs    = []
    @started = false
    @debug   = debug

    if blocks.any?
      blocks.each { |block| add &block }
    else
      yield self if block_given?
    end
  end

  def dmsg(msg)
    puts "[#{Time.now}] #{msg}" if @debug
  end

  def add(&block)
    dmsg("added job #{block}")
    @jobs << block
  end

  def reap!
    if @threads.any?
      dmsg("reaping #{@threads.size} threads")
      @threads.delete_if { |t| not t.alive? }
    else
      dmsg("reap failed: no threads")
    end
  end

  def go!
    if @started
      raise "Error: already started"
    else
      dmsg("starting #{@threads.size} jobs")
    end

    @started = true
    @jobs.each do |job|
      dmsg("adding #{job}")
      @threads << Thread.new do
        @results << job.call
        dmsg("job #{job} complete")
      end
    end
  end

  def each_result
    go! unless @started

    loop do
      yield @results.pop
      reap!
      break if @threads.empty? and @results.empty?
    end

    @started = false
  end
end


if __FILE__ == $0
  JobRunner.new(debug: true) do |jr|
    jr.add { 3 }
    jr.add { sleep 0.1; 2 }
    jr.add { sleep 0.2; 1 }

    jr.each_result do |result|
      p result
    end
  end

  puts

  jr = JobRunner.new(
    proc { 1 },
    proc { 2 },
    proc { 3 }
  )

  2.times do
    jr.each_result { |r| p r }
    puts
  end
end