require 'epitools'

class String

  #
  # Find all occurrences of "pattern" in the string and highlight them
  # with the specified color. (defaults to light_yellow)
  #
  # The pattern can be a string or a regular expression.
  #
  def highlight(pattern, color=:light_yellow)
    pattern = Regexp.new(Regexp.escape(pattern)) if pattern.is_a? String
    gsub(pattern) { |match| match.send(color) }
  end

end

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

rescue Errno::EPIPE
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

