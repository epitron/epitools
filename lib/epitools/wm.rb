module WM

  raise "Error: wmctrl not found." unless Path.which("wmctrl")

  def self.windows;           @windows    ||= Window.all; end
  def self.desktops;          @desktops   ||= Desktop.all; end
  def self.processes;         @processes  ||= Hash[ Sys.ps.map { |process| [process.pid, process] } ] ; end
  def self.current_desktop;   @current    ||= desktops.find { |d| d.current? }; end
  def self.sticky;            @sticky     ||= windows.select { |w| w.sticky? }; end

  class Desktop < TypedStruct["num:int current:bool resolution viewport desktop_geometry name"]
    def self.all
      # 0  - DG: 1680x1050  VP: N/A  WA: 0,25 1680x974  Workspace 1
      # 1  - DG: 1680x1050  VP: N/A  WA: 0,25 1680x974  Workspace 2
      # 2  * DG: 1680x1050  VP: 0,0  WA: 0,25 1680x974  Workspace 3
      # 3  - DG: 1680x1050  VP: N/A  WA: 0,25 1680x974  Workspace 4
      # 4  - DG: 1680x1050  VP: N/A  WA: 0,25 1680x974  Workspace 5
      # 5  - DG: 1680x1050  VP: N/A  WA: 0,25 1680x974  Workspace 6
      # 0  1 2   3          4   5    6   7    8         9
      `wmctrl -d`.lines.map(&:strip).map { |line| Desktop.from_line(line) }
    end

    def self.from_line(line)
      fields = line.split
      fields[1] = (fields[1] == "*") # cast to boolean
      fields[5] = nil if fields[5] == "N/A" # N/A becomes nil
      
      name = fields[9..-1].join(" ")
      
      new *(fields.values_at(0,1,3,5,8) + [name])
    end    

    def current?
      current
    end

    def windows
      @windows ||= WM.windows.select { |w| w.desktop_id == num }
    end
  end


  class Window < TypedStruct["addr desktop_id:int pid:int x:int y:int w:int h:int hostname title"]

    def self.all
      `wmctrl -lpG`.lines.map(&:strip).map { |line| Window.from_line(line) }
    end

    def self.from_line(line)
      # 0x01600031 -1 2562   0    0    1680 25   fizz Top Expanded Edge Panel
      # 0x01600003 -1 2562   0    1998 1680 51   fizz Bottom Expanded Edge Panel
      # 0x02c0001f  0 3012   849  173  783  667  fizz Terminal
      # 0x048001f8  5 4080   311  186  1316 835  fizz Gorillaz - Highway (Under Construction)
      # 0x02c28577  4 3012   66   461  1143 548  fizz Terminal
      # 0x07c00003  0 14117  12   73   1298 948  fizz tr1984001_comp_soft.pdf
      # 0x02d767d8  2 3012   520  470  1143 548  fizz Terminal    

      fields = line.split
      title  = fields[8..-1].join ' '

      new *(fields[0..7] + [title])
    end

    def desktop
      WM.desktops[desktop_id]
    end

    def sticky?
      desktop_id == -1
    end

    alias_method :name, :title

    def process
      WM.processes[pid]
    end

    def inspect
      "{ ::#{name}:: [#{desktop_id}]}"
    end
  end

end
