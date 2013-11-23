module Term

  class Window

    class State < Struct.new :wrap, :width, :height, :x, :y
    end

    attr_accessor :state

    def initialize(opts={})
      # valid option sets:
      # [:x, :y, :width, :height]
      # [:x, :y, :w, :h]
      # [:left, :right, :top, :bottom]

      @state = State.new(wrap, width, height, x, y)

      @width, @height = Term.size

      for k,v in opts
        send("#{k}=", v)
      end
    end

    [:width, :height].each do |dim|
      class_eval %{
        def #{dim}=(val)
          dimsize = Term.#{dim}

          if val < 0
            @#{dim} = dimsize - (val+1)
          else
            @#{dim} = val < dimsize ? val : dimsize
          end
        end
      }
    end

    def scroll(delta_x, delta_y)
      state.
    end

    def scroll_x(amount)
      scroll(amount, 0)
    end

    def scroll_y(amount)
      scroll(0, amount)
    end

    def puts(s)
      lines << s
      refresh
    end
  end

end