module Term

  extend self

  attr_accessor :wrap, :x, :y

  #
  # Return the [width,height] of the terminal.
  #
  def size
    STDIN.winsize.reverse
  end

  def width;  size[0]; end
  def height; size[1]; end
  def goto(x,y); @x, @y = x, y; end
  def pos; [@x, @y]; end

  def clear
    print "\e[H\e[J"
  end

  def color(fore, back=nil)
    @fore = fore
    @back = back if back
  end

  def puts(s)
    # some curses shit
  end

end