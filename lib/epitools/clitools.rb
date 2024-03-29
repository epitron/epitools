#
# Create scrollable output via less!
#
# This command runs `less` in a subprocess, and gives you the IO to its STDIN pipe
# so that you can communicate with it.
#
# Example:
#
#   lesspipe do |less|
#     50.times { less.puts "Hi mom!" }
#   end
#
# The default less parameters are:
# * Allow colour
# * Don't wrap lines longer than the screen
# * Quit immediately (without paging) if there's less than one screen of text.
#
# You can change these options by passing a hash to `lesspipe`, like so:
#
#   lesspipe(:wrap=>false) { |less| less.puts essay.to_s }
#
# It accepts the following boolean options:
#    :color  => Allow ANSI colour codes?
#    :wrap   => Wrap long lines?
#    :always => Always page, even if there's less than one page of text?
#
def lesspipe(*args)
  if args.any? and args.last.is_a?(Hash)
    options = args.pop
  else
    options = {}
  end

  output = args.first if args.any?

  params = []
  params << "-R" unless options[:color] == false
  params << "-S" unless options[:wrap] == true
  params << "-F" unless options[:always] == true
  if options[:tail] == true
    params << "+\\>"
    $stderr.puts "Seeking to end of stream..."
  end
  params << "-X"

  IO.popen("less #{params * ' '}", "w") do |less|
    if output
      less.puts output
    else
      yield less
    end
  end

rescue Errno::EPIPE, Interrupt
  # less just quit -- eat the exception.
end


#
# Colorized puts (see: `String#colorize`)
#
def cputs(*args)
  puts args.join("\n").colorize
end

#
# Execute a `system()` command using SQL-style escaped arguments.
#
# Example:
#    cmd( ["cp -arv ? ?", "/usr/src", "/home/you/A Folder/dest"] )
#
# Which is equivalent to:
#    system( "cp", "-arv", "/usr/src", "/home/you/A Folder/dest" )
#
# Notice that you don't need to shell-escape anything.
# That's done automagically!
#
# If you don't pass any arrays, `cmd` works the same as `system`:
#    cmd( "cp", "-arv", "etc", "etc" )
#
def cmd(*args)

  cmd_args = []

  for arg in args

    case arg

      when Array
        cmd_literals = arg.shift.split(/\s+/)

        for cmd_literal in cmd_literals
          if cmd_literal == "?"
            raise "Not enough substitution arguments" unless cmd_args.any?
            cmd_args << arg.shift
          else
            cmd_args << cmd_literal
          end
        end

        raise "More parameters than ?'s in cmd string" if arg.any?

      when String
        cmd_args << arg

      else
        cmd_args << arg.to_s

    end

  end

  p [:cmd_args, cmd_args] if $DEBUG

  system(*cmd_args)
end


#
# Prompt the user for confirmation.
#
# Usage:
#   prompt("Do you want a cookie?", "Ynqa") #=> returns the letter that the user pressed, in lowercase (and returns the default, 'y', if the user hits ENTER)
#
def prompt(message="Are you sure?", options="Yn")
  opts      = options.scan(/./)
  optstring = opts.join("/") # case maintained
  defaults  = opts.select{|o| o.upcase == o }
  opts      = opts.map{|o| o.downcase}

  raise "Error: Too many default values for the prompt: #{default.inspect}" if defaults.size > 1

  default = defaults.first

  loop do

    print "#{message} (#{optstring}) "

    response = STDIN.gets.strip.downcase

    case response
    when *opts
      return response
    when ""
      return default.downcase
    else
      puts "  |_ Invalid option: #{response.inspect}. Try again."
    end

  end
end


#
# Automatically install a required commandline tool using the platform's package manager (incomplete -- only supports debian :)
#
# * apt-get on debian/ubuntu
# * yum on fedora
# * fink/ports on OSX
# * cygwin on windows
#
def autoinstall(*packages)
  all_packages_installed = packages.all? { |pkg| Path.which pkg }

  unless all_packages_installed
    cmd(["sudo apt-get install ?", packages.join(' ')])
  end
end


#
# Re-execute the script using sudo if it's not currently running as root.
#
def sudoifnotroot
  unless Process.uid == 0
    exit system("sudo", $PROGRAM_NAME, *ARGV)
  end
end

#
# Lookup GeoIP information (city, state, country, etc.) for an IP address or hostname
#
# (Note: Must be able to find one of /usr/share/GeoIP/GeoIP{,City}.dat, or specified manually
#        as (an) extra argument(s).)
#
def geoip(addr, city_data='/usr/share/GeoIP/GeoIPCity.dat', country_data='/usr/share/GeoIP/GeoIP.dat')
  (
    $geoip ||= begin
      if city_data and File.exist? city_data
        geo = GeoIP.new city_data
        proc { |addr| geo.city(addr) }

      elsif country_data and File.exist? country_data
        geo = GeoIP.new country_data
        proc { |addr| geo.country(addr) }

      else
        raise "Can't find GeoIP data files."
      end
    end
  ).call(addr)
end


#
# Search the PATH environment variable for binaries, returning the first one that exists
#
def which(*bins)
  bins.flatten.each do |bin|
    ENV["PATH"].split(":").each do |dir|
      full_path = File.join(dir, bin)
      return full_path if File.exist? full_path
    end
  end
  nil
end


#
# Executes notify-send to create a desktop notification on the user's desktop
#
# Note: the 'icon' argument is the path to an image file
#
def notify_send(title, body=nil, icon: nil, time: 5)
  $stderr.puts "* #{title}"
  $stderr.puts "  |_ #{body}" if body

  time_in_ms = time * 1000

  cmd = ["notify-send"]
  cmd << "--expire-time=#{time_in_ms}"
  cmd << "--app-name=#{Process.argv0}"
  cmd << "--icon=#{icon}" if icon
  cmd << CGI.escapeHTML(title)
  cmd << CGI.escapeHTML(body) if body

  fork { system *cmd }
end

def curl(url)
  curl_open(url).read
end

def curl_open(url, **headers)
  # headers["User-Agent"] ||= "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/85 Version/11.1.1 Safari/605.1.15"
  cmd = ["curl", "-LSs"]
  headers.each { |k,v| cmd += ["-H", "#{k}: #{v}"] }
  cmd << url
  IO.popen(cmd)
rescue Errno::ENOENT
  raise "Error: 'curl' isn't installed."
end

def curl_json(url)
  JSON.parse(curl(url))
end

def cached_curl(url)
  cache = "/tmp/curl-#{url.sha1}.cache"
  if File.exist?(cache)
    $stderr.puts "cached! => #{cache}"
  else
    File.write(cache, curl(url))
  end
  File.read(cache)
end
