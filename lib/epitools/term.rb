require 'epitools'

class Term

  #
  # Return the [width,height] of the terminal.
  #
  def self.size
    Curses.init_screen
    result = [Curses.cols, Curses.lines]
    Curses.close_screen
    result
  end
  
  
  class Table

    attr_accessor :border, :columns, :padding, :strip_color, :indent
  
    def self.[](data)
      self.new(data)
    end
  
    def initialize(data, options={})
      @data         = data.map(&:to_s)
      @strip_color = options[:strip_color] || options[:strip_ansi]

      if strip_color
        @max_size = @data.map { |e| e.strip_color.size }.max
      else
        @max_size = @data.map(&:size).max
      end
      
      @indent   = options[:indent]  || 0
      @border   = options[:border]
      @columns  = options[:columns]
      @padding  = options[:padding] || 1
    end
    
    def num_columns
      return @columns if @columns
      width, height = Term.size
      width -= indent
      (width-2) / (@max_size + @padding)
    end
    
    def num_rows
      (@data.size / num_columns.to_f).ceil
    end
    
    def column_order
      cols = []
      @data.each_slice(num_rows) { |col| cols << col }
      if (diff = cols.first.size - cols.last.size) > 0
        cols.last.concat [''] * diff
      end
      cols.transpose
    end

    def row_order
      rows = []
      @data.each_slice(num_columns) { |row| rows << row }
      if (diff = rows.first.size - rows.last.size) > 0
        rows.last.concat [''] * diff
      end
      rows
    end
    
    def sliced_into(n)
      elems = []
      @data.each_slice(n) { |e| elems << e }
      if (diff = elems.first.size - elems.last.size) > 0
        elems.last.concat [''] * diff
      end
      elems
    end
    
    def by_columns
      return '' if @data.empty?
      render sliced_into(num_rows).transpose
    end
    
    def by_rows
      return '' if @data.empty?
      render sliced_into(num_columns)
    end
    
    def render(rows, options={})
      num_cols  = rows.first.size
      result    = []
      
      if @border
        separator = "+#{(["-" * @max_size] * num_cols).join('+')}+"
        result << separator
      end  
        
      for row in rows
        
        justified = row.map do |e|
          if (diff = @max_size - e.strip_color.size) > 0
            e = e + (" " * diff)
          end
          e
        end

        if @border
          line = "|#{justified.join('|')}|"
        else
          line = justified.join(' '*@padding)
        end 
        
        result << (" "*indent) + line
      end
      
      result << separator if @border
      
      result.join("\n")
    end
    
  end
  
end
