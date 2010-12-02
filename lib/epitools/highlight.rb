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

