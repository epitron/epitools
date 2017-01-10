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


GEOIP_COUNTRY_DATA = '/usr/share/GeoIP/GeoIP.dat'
GEOIP_CITY_DATA    = '/usr/share/GeoIP/GeoIPCity.dat'

def geoip(addr)
  $geoip ||= begin
    if File.exists? GEOIP_CITY_DATA
      geo = GeoIP.new GEOIP_CITY_DATA
      proc { |addr| geo.city(addr) }

    elsif File.exists? GEOIP_COUNTRY_DATA
      geo = GeoIP.new GEOIP_COUNTRY_DATA
      proc { |addr| geo.country(addr) }

    else
      raise "Can't find GeoIP data in /usr/share/GeoIP."
    end
  end

  $geoip.call(addr)
end


def which(*bins)
  ENV["PATH"].split(":").each do |dir|
    bins.flatten.each do |bin|
      full_path = File.join(dir, bin)
      return full_path if File.exists? full_path
    end
  end
  nil
end
