require 'epitools/colored'

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
# Output to less.
#
def lesspipe(output=nil, options={})
  params = []
  params << "-R" unless options[:color] == false
  params << "-S" unless options[:wrap] == true
  params << "-X"
  IO.popen("less #{params * ' '}", "w") do |less|
    if output
      less.puts output
    else
      yield less
    end
  end
end
