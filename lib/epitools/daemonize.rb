module Kernel
  # This method causes the current running process to become a daemon
  # All further printing is relied to the error.log
  # FIXME doesn't belong into Butler::Bot, rather into botcontrol
  def daemonize(chdir=nil, &on_sighup)
    srand # Split rand streams between spawning and daemonized process
    safe_fork and exit # Fork and exit from the parent

    # Detach from the controlling terminal
    raise "Can't detach from controlling terminal" unless sess_id = Process.setsid

    # Prevent the possibility of acquiring a controlling terminal
    trap('SIGHUP', 'IGNORE')
    exit if safe_fork

    # In daemon mode, a SIGHUP means termination
    trap('SIGHUP', &on_sighup)

    # We can't get the originally controlling terminals stdout/stdin anymore
    STDIN.reopen("/dev/null")
    STDOUT.reopen("/dev/null", "a")
    STDERR.reopen(STDOUT)

    Dir.chdir(chdir) if chdir
    File.umask 0033 # FIXME ask somebody knowledgable about a sensible value

    sess_id
  end

  # Try to fork if at all possible retrying every +delay+ sec (5s default)
  # if the maximum process limit for the system has been reached
  def safe_fork(delay=5)
    fork
  rescue Errno::EWOULDBLOCK
    sleep(delay)
    retry
  end
end
