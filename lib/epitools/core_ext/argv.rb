class << ARGV

  def parse!
    unless @opts or @args
      @opts, @args = partition { |arg| arg[/^--?\w{1,2}/].nil? }
      @opts = @opts.map { |opt| key, val = opt.strip(/^-+/).split("=") }.to_ostruct
      if @opts.help
        @help_handler.call
        exit
      end
    end

    [@opts, @args]
  end

  def parse
    parse!
    [@opts, @args]
  end

  def help?
    !!@opts["help"]
  end

  def opts
    parse! unless @opts
    @opts
  end

  def args
    @args ? @args : opts && @args
  end

  def paths
    map(&:to_Path)
  end

  def paths_R
    recursive_proc = proc do |paths|
      paths.map { |path| path.dir? ? the_expander.(path.ls_R) : path }
    end

    recursive_proc.(paths)
  end
  alias_method :recursive_paths, :paths_R

  def on_help(&block)
    @help_handler = block
  end

  def regexes(escaped: true, case_sensitive: false)
    if case_sensitive
      map { |arg| /#{escaped ? Regexp.escape(arg) : arg}/ } # NO 'i'
    else
      map { |arg| /#{escaped ? Regexp.escape(arg) : arg}/i }
    end
  end

end
