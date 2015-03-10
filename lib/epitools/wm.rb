require 'epitools/path'
require 'epitools/typed_struct'

module WM

  raise "Error: wmctrl not found." unless Path.which("wmctrl")

  def self.windows;           @windows    ||= Window.all; end
  def self.desktops;          @desktops   ||= Desktop.all; end
  def self.processes;         @processes  ||= Hash[ Sys.ps.map { |pr| [pr.pid, pr] } ] ; end
  def self.current_desktop;   @current    ||= desktops.find { |d| d.current? }; end
  def self.sticky;            @sticky     ||= windows.select { |w| w.sticky? }; end

  def self.window(pid)
    results = windows.select { |w| w.pid }

    if results.empty?
      # check the children
      results = windows.select { |w| w.process.children.any? {|pr| pr.pid == pid } }
    end
    
    results
  end


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

    alias_method :active?, :current?

    def windows
      @windows ||= WM.windows.select { |w| w.desktop_id == num }
    end
  end


  class Window < TypedStruct["window_id desktop_id:int pid:int x:int y:int w:int h:int hostname title"]

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
    alias_method :addr, :window_id

    def process
      WM.processes[pid]
    end

    def command
      process && process.command
    end

    def inspect
      "{ ::#{name}:: [#{desktop_id}]}"
    end

    def activate!
      system "wmctrl", "-i", "-a", window_id
    end

    #
    # string is made up of regular text, plus <>'d keypresses
    # eg: "Hello<Ctrl-T><Ctrl-L><Ctrl-Shift-K><Return>!!!"
    #
    # TODO: add `xdotool` support
    #
    def send_keys(keys)
      xse(keys)
    end

    #
    # LATIN-1 XSendKey event names:
    # ------------------------------------------------------
    # (from /usr/include/X11/keysymdef.h, XK_LATIN1 section)
    #
    # space                         0x0020  /* U+0020 SPACE */
    # exclam                        0x0021  /* U+0021 EXCLAMATION MARK */
    # quotedbl                      0x0022  /* U+0022 QUOTATION MARK */
    # numbersign                    0x0023  /* U+0023 NUMBER SIGN */
    # dollar                        0x0024  /* U+0024 DOLLAR SIGN */
    # percent                       0x0025  /* U+0025 PERCENT SIGN */
    # ampersand                     0x0026  /* U+0026 AMPERSAND */
    # apostrophe                    0x0027  /* U+0027 APOSTROPHE */
    # quoteright                    0x0027  /* deprecated */
    # parenleft                     0x0028  /* U+0028 LEFT PARENTHESIS */
    # parenright                    0x0029  /* U+0029 RIGHT PARENTHESIS */
    # asterisk                      0x002a  /* U+002A ASTERISK */
    # plus                          0x002b  /* U+002B PLUS SIGN */
    # comma                         0x002c  /* U+002C COMMA */
    # minus                         0x002d  /* U+002D HYPHEN-MINUS */
    # period                        0x002e  /* U+002E FULL STOP */
    # slash                         0x002f  /* U+002F SOLIDUS */
    # 0                             0x0030  /* U+0030 DIGIT ZERO */
    # 1                             0x0031  /* U+0031 DIGIT ONE */
    # 2                             0x0032  /* U+0032 DIGIT TWO */
    # 3                             0x0033  /* U+0033 DIGIT THREE */
    # 4                             0x0034  /* U+0034 DIGIT FOUR */
    # 5                             0x0035  /* U+0035 DIGIT FIVE */
    # 6                             0x0036  /* U+0036 DIGIT SIX */
    # 7                             0x0037  /* U+0037 DIGIT SEVEN */
    # 8                             0x0038  /* U+0038 DIGIT EIGHT */
    # 9                             0x0039  /* U+0039 DIGIT NINE */
    # colon                         0x003a  /* U+003A COLON */
    # semicolon                     0x003b  /* U+003B SEMICOLON */
    # less                          0x003c  /* U+003C LESS-THAN SIGN */
    # equal                         0x003d  /* U+003D EQUALS SIGN */
    # greater                       0x003e  /* U+003E GREATER-THAN SIGN */
    # question                      0x003f  /* U+003F QUESTION MARK */
    # at                            0x0040  /* U+0040 COMMERCIAL AT */
    # A                             0x0041  /* U+0041 LATIN CAPITAL LETTER A */
    # B                             0x0042  /* U+0042 LATIN CAPITAL LETTER B */
    # C                             0x0043  /* U+0043 LATIN CAPITAL LETTER C */
    # D                             0x0044  /* U+0044 LATIN CAPITAL LETTER D */
    # E                             0x0045  /* U+0045 LATIN CAPITAL LETTER E */
    # F                             0x0046  /* U+0046 LATIN CAPITAL LETTER F */
    # G                             0x0047  /* U+0047 LATIN CAPITAL LETTER G */
    # H                             0x0048  /* U+0048 LATIN CAPITAL LETTER H */
    # I                             0x0049  /* U+0049 LATIN CAPITAL LETTER I */
    # J                             0x004a  /* U+004A LATIN CAPITAL LETTER J */
    # K                             0x004b  /* U+004B LATIN CAPITAL LETTER K */
    # L                             0x004c  /* U+004C LATIN CAPITAL LETTER L */
    # M                             0x004d  /* U+004D LATIN CAPITAL LETTER M */
    # N                             0x004e  /* U+004E LATIN CAPITAL LETTER N */
    # O                             0x004f  /* U+004F LATIN CAPITAL LETTER O */
    # P                             0x0050  /* U+0050 LATIN CAPITAL LETTER P */
    # Q                             0x0051  /* U+0051 LATIN CAPITAL LETTER Q */
    # R                             0x0052  /* U+0052 LATIN CAPITAL LETTER R */
    # S                             0x0053  /* U+0053 LATIN CAPITAL LETTER S */
    # T                             0x0054  /* U+0054 LATIN CAPITAL LETTER T */
    # U                             0x0055  /* U+0055 LATIN CAPITAL LETTER U */
    # V                             0x0056  /* U+0056 LATIN CAPITAL LETTER V */
    # W                             0x0057  /* U+0057 LATIN CAPITAL LETTER W */
    # X                             0x0058  /* U+0058 LATIN CAPITAL LETTER X */
    # Y                             0x0059  /* U+0059 LATIN CAPITAL LETTER Y */
    # Z                             0x005a  /* U+005A LATIN CAPITAL LETTER Z */
    # bracketleft                   0x005b  /* U+005B LEFT SQUARE BRACKET */
    # backslash                     0x005c  /* U+005C REVERSE SOLIDUS */
    # bracketright                  0x005d  /* U+005D RIGHT SQUARE BRACKET */
    # asciicircum                   0x005e  /* U+005E CIRCUMFLEX ACCENT */
    # underscore                    0x005f  /* U+005F LOW LINE */
    # grave                         0x0060  /* U+0060 GRAVE ACCENT */
    # quoteleft                     0x0060  /* deprecated */
    # a                             0x0061  /* U+0061 LATIN SMALL LETTER A */
    # b                             0x0062  /* U+0062 LATIN SMALL LETTER B */
    # c                             0x0063  /* U+0063 LATIN SMALL LETTER C */
    # d                             0x0064  /* U+0064 LATIN SMALL LETTER D */
    # e                             0x0065  /* U+0065 LATIN SMALL LETTER E */
    # f                             0x0066  /* U+0066 LATIN SMALL LETTER F */
    # g                             0x0067  /* U+0067 LATIN SMALL LETTER G */
    # h                             0x0068  /* U+0068 LATIN SMALL LETTER H */
    # i                             0x0069  /* U+0069 LATIN SMALL LETTER I */
    # j                             0x006a  /* U+006A LATIN SMALL LETTER J */
    # k                             0x006b  /* U+006B LATIN SMALL LETTER K */
    # l                             0x006c  /* U+006C LATIN SMALL LETTER L */
    # m                             0x006d  /* U+006D LATIN SMALL LETTER M */
    # n                             0x006e  /* U+006E LATIN SMALL LETTER N */
    # o                             0x006f  /* U+006F LATIN SMALL LETTER O */
    # p                             0x0070  /* U+0070 LATIN SMALL LETTER P */
    # q                             0x0071  /* U+0071 LATIN SMALL LETTER Q */
    # r                             0x0072  /* U+0072 LATIN SMALL LETTER R */
    # s                             0x0073  /* U+0073 LATIN SMALL LETTER S */
    # t                             0x0074  /* U+0074 LATIN SMALL LETTER T */
    # u                             0x0075  /* U+0075 LATIN SMALL LETTER U */
    # v                             0x0076  /* U+0076 LATIN SMALL LETTER V */
    # w                             0x0077  /* U+0077 LATIN SMALL LETTER W */
    # x                             0x0078  /* U+0078 LATIN SMALL LETTER X */
    # y                             0x0079  /* U+0079 LATIN SMALL LETTER Y */
    # z                             0x007a  /* U+007A LATIN SMALL LETTER Z */
    # braceleft                     0x007b  /* U+007B LEFT CURLY BRACKET */
    # bar                           0x007c  /* U+007C VERTICAL LINE */
    # braceright                    0x007d  /* U+007D RIGHT CURLY BRACKET */
    # asciitilde                    0x007e  /* U+007E TILDE */
    # nobreakspace                  0x00a0  /* U+00A0 NO-BREAK SPACE */
    # exclamdown                    0x00a1  /* U+00A1 INVERTED EXCLAMATION MARK */
    # cent                          0x00a2  /* U+00A2 CENT SIGN */
    # sterling                      0x00a3  /* U+00A3 POUND SIGN */
    # currency                      0x00a4  /* U+00A4 CURRENCY SIGN */
    # yen                           0x00a5  /* U+00A5 YEN SIGN */
    # brokenbar                     0x00a6  /* U+00A6 BROKEN BAR */
    # section                       0x00a7  /* U+00A7 SECTION SIGN */
    # diaeresis                     0x00a8  /* U+00A8 DIAERESIS */
    # copyright                     0x00a9  /* U+00A9 COPYRIGHT SIGN */
    # ordfeminine                   0x00aa  /* U+00AA FEMININE ORDINAL INDICATOR */
    # guillemotleft                 0x00ab  /* U+00AB LEFT-POINTING DOUBLE ANGLE QUOTATION MARK */
    # notsign                       0x00ac  /* U+00AC NOT SIGN */
    # hyphen                        0x00ad  /* U+00AD SOFT HYPHEN */
    # registered                    0x00ae  /* U+00AE REGISTERED SIGN */
    # macron                        0x00af  /* U+00AF MACRON */
    # degree                        0x00b0  /* U+00B0 DEGREE SIGN */
    # plusminus                     0x00b1  /* U+00B1 PLUS-MINUS SIGN */
    # twosuperior                   0x00b2  /* U+00B2 SUPERSCRIPT TWO */
    # threesuperior                 0x00b3  /* U+00B3 SUPERSCRIPT THREE */
    # acute                         0x00b4  /* U+00B4 ACUTE ACCENT */
    # mu                            0x00b5  /* U+00B5 MICRO SIGN */
    # paragraph                     0x00b6  /* U+00B6 PILCROW SIGN */
    # periodcentered                0x00b7  /* U+00B7 MIDDLE DOT */
    # cedilla                       0x00b8  /* U+00B8 CEDILLA */
    # onesuperior                   0x00b9  /* U+00B9 SUPERSCRIPT ONE */
    # masculine                     0x00ba  /* U+00BA MASCULINE ORDINAL INDICATOR */
    # guillemotright                0x00bb  /* U+00BB RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK */
    # onequarter                    0x00bc  /* U+00BC VULGAR FRACTION ONE QUARTER */
    # onehalf                       0x00bd  /* U+00BD VULGAR FRACTION ONE HALF */
    # threequarters                 0x00be  /* U+00BE VULGAR FRACTION THREE QUARTERS */
    # questiondown                  0x00bf  /* U+00BF INVERTED QUESTION MARK */
    # Agrave                        0x00c0  /* U+00C0 LATIN CAPITAL LETTER A WITH GRAVE */
    # Aacute                        0x00c1  /* U+00C1 LATIN CAPITAL LETTER A WITH ACUTE */
    # Acircumflex                   0x00c2  /* U+00C2 LATIN CAPITAL LETTER A WITH CIRCUMFLEX */
    # Atilde                        0x00c3  /* U+00C3 LATIN CAPITAL LETTER A WITH TILDE */
    # Adiaeresis                    0x00c4  /* U+00C4 LATIN CAPITAL LETTER A WITH DIAERESIS */
    # Aring                         0x00c5  /* U+00C5 LATIN CAPITAL LETTER A WITH RING ABOVE */
    # AE                            0x00c6  /* U+00C6 LATIN CAPITAL LETTER AE */
    # Ccedilla                      0x00c7  /* U+00C7 LATIN CAPITAL LETTER C WITH CEDILLA */
    # Egrave                        0x00c8  /* U+00C8 LATIN CAPITAL LETTER E WITH GRAVE */
    # Eacute                        0x00c9  /* U+00C9 LATIN CAPITAL LETTER E WITH ACUTE */
    # Ecircumflex                   0x00ca  /* U+00CA LATIN CAPITAL LETTER E WITH CIRCUMFLEX */
    # Ediaeresis                    0x00cb  /* U+00CB LATIN CAPITAL LETTER E WITH DIAERESIS */
    # Igrave                        0x00cc  /* U+00CC LATIN CAPITAL LETTER I WITH GRAVE */
    # Iacute                        0x00cd  /* U+00CD LATIN CAPITAL LETTER I WITH ACUTE */
    # Icircumflex                   0x00ce  /* U+00CE LATIN CAPITAL LETTER I WITH CIRCUMFLEX */
    # Idiaeresis                    0x00cf  /* U+00CF LATIN CAPITAL LETTER I WITH DIAERESIS */
    # ETH                           0x00d0  /* U+00D0 LATIN CAPITAL LETTER ETH */
    # Eth                           0x00d0  /* deprecated */
    # Ntilde                        0x00d1  /* U+00D1 LATIN CAPITAL LETTER N WITH TILDE */
    # Ograve                        0x00d2  /* U+00D2 LATIN CAPITAL LETTER O WITH GRAVE */
    # Oacute                        0x00d3  /* U+00D3 LATIN CAPITAL LETTER O WITH ACUTE */
    # Ocircumflex                   0x00d4  /* U+00D4 LATIN CAPITAL LETTER O WITH CIRCUMFLEX */
    # Otilde                        0x00d5  /* U+00D5 LATIN CAPITAL LETTER O WITH TILDE */
    # Odiaeresis                    0x00d6  /* U+00D6 LATIN CAPITAL LETTER O WITH DIAERESIS */
    # multiply                      0x00d7  /* U+00D7 MULTIPLICATION SIGN */
    # Oslash                        0x00d8  /* U+00D8 LATIN CAPITAL LETTER O WITH STROKE */
    # Ooblique                      0x00d8  /* U+00D8 LATIN CAPITAL LETTER O WITH STROKE */
    # Ugrave                        0x00d9  /* U+00D9 LATIN CAPITAL LETTER U WITH GRAVE */
    # Uacute                        0x00da  /* U+00DA LATIN CAPITAL LETTER U WITH ACUTE */
    # Ucircumflex                   0x00db  /* U+00DB LATIN CAPITAL LETTER U WITH CIRCUMFLEX */
    # Udiaeresis                    0x00dc  /* U+00DC LATIN CAPITAL LETTER U WITH DIAERESIS */
    # Yacute                        0x00dd  /* U+00DD LATIN CAPITAL LETTER Y WITH ACUTE */
    # THORN                         0x00de  /* U+00DE LATIN CAPITAL LETTER THORN */
    # Thorn                         0x00de  /* deprecated */
    # ssharp                        0x00df  /* U+00DF LATIN SMALL LETTER SHARP S */
    # agrave                        0x00e0  /* U+00E0 LATIN SMALL LETTER A WITH GRAVE */
    # aacute                        0x00e1  /* U+00E1 LATIN SMALL LETTER A WITH ACUTE */
    # acircumflex                   0x00e2  /* U+00E2 LATIN SMALL LETTER A WITH CIRCUMFLEX */
    # atilde                        0x00e3  /* U+00E3 LATIN SMALL LETTER A WITH TILDE */
    # adiaeresis                    0x00e4  /* U+00E4 LATIN SMALL LETTER A WITH DIAERESIS */
    # aring                         0x00e5  /* U+00E5 LATIN SMALL LETTER A WITH RING ABOVE */
    # ae                            0x00e6  /* U+00E6 LATIN SMALL LETTER AE */
    # ccedilla                      0x00e7  /* U+00E7 LATIN SMALL LETTER C WITH CEDILLA */
    # egrave                        0x00e8  /* U+00E8 LATIN SMALL LETTER E WITH GRAVE */
    # eacute                        0x00e9  /* U+00E9 LATIN SMALL LETTER E WITH ACUTE */
    # ecircumflex                   0x00ea  /* U+00EA LATIN SMALL LETTER E WITH CIRCUMFLEX */
    # ediaeresis                    0x00eb  /* U+00EB LATIN SMALL LETTER E WITH DIAERESIS */
    # igrave                        0x00ec  /* U+00EC LATIN SMALL LETTER I WITH GRAVE */
    # iacute                        0x00ed  /* U+00ED LATIN SMALL LETTER I WITH ACUTE */
    # icircumflex                   0x00ee  /* U+00EE LATIN SMALL LETTER I WITH CIRCUMFLEX */
    # idiaeresis                    0x00ef  /* U+00EF LATIN SMALL LETTER I WITH DIAERESIS */
    # eth                           0x00f0  /* U+00F0 LATIN SMALL LETTER ETH */
    # ntilde                        0x00f1  /* U+00F1 LATIN SMALL LETTER N WITH TILDE */
    # ograve                        0x00f2  /* U+00F2 LATIN SMALL LETTER O WITH GRAVE */
    # oacute                        0x00f3  /* U+00F3 LATIN SMALL LETTER O WITH ACUTE */
    # ocircumflex                   0x00f4  /* U+00F4 LATIN SMALL LETTER O WITH CIRCUMFLEX */
    # otilde                        0x00f5  /* U+00F5 LATIN SMALL LETTER O WITH TILDE */
    # odiaeresis                    0x00f6  /* U+00F6 LATIN SMALL LETTER O WITH DIAERESIS */
    # division                      0x00f7  /* U+00F7 DIVISION SIGN */
    # oslash                        0x00f8  /* U+00F8 LATIN SMALL LETTER O WITH STROKE */
    # ooblique                      0x00f8  /* U+00F8 LATIN SMALL LETTER O WITH STROKE */
    # ugrave                        0x00f9  /* U+00F9 LATIN SMALL LETTER U WITH GRAVE */
    # uacute                        0x00fa  /* U+00FA LATIN SMALL LETTER U WITH ACUTE */
    # ucircumflex                   0x00fb  /* U+00FB LATIN SMALL LETTER U WITH CIRCUMFLEX */
    # udiaeresis                    0x00fc  /* U+00FC LATIN SMALL LETTER U WITH DIAERESIS */
    # yacute                        0x00fd  /* U+00FD LATIN SMALL LETTER Y WITH ACUTE */
    # thorn                         0x00fe  /* U+00FE LATIN SMALL LETTER THORN */
    # ydiaeresis                    0x00ff  /* U+00FF LATIN SMALL LETTER Y WITH DIAERESIS */
    #
    if Path.which("xse")

      KEYMAP = {
        "`" => "grave",
        " " => "space",
        "~" => "asciitilde",
        "_" => "underscore",
        "\[" => "Escape",
        '"' => "quotedbl",
      }
      def keys_to_events(keys)

        tokens = keys.scan(/(<[^>]+>|.+?)/)

        tokens.flatten.map do |key|
          mods = []

          if key =~ /^<(.+)>$/

            specials = $1.split("-")
            key = specials.pop

            key.downcase! if key =~ /^[A-Z]$/

            specials.each do |special|
              if special =~ /^(Ctrl|Shift|Alt)$/i
                mods << $1
              else
                raise "Error: unknown modifier #{special}"
              end
            end

          end

          mods << "Shift" if key =~ /^[A-Z\~\!\@\#\$\%\^\&\*\(\)\_\+]$/

          if key =~ /^[A-Z0-9]$/i or key.size > 1
            keyname = key
          else
            keyname = KEYMAP[key] || ("0x%x" % key.ord)
          end

          "#{mods.join(" ")}<Key>#{keyname}"
        end
      end

      def xse(keys)
        temp   = Tempfile.new("xse")
        events = keys_to_events(keys)

        # p events
        eventstring = events.map { |e| e + "\n" }.join("")

        temp.write eventstring 
        temp.flush
        temp.seek 0
        # p [:temp, temp.read]

        cmd = "xse", "-window", window_id, "-file", temp.path
        # p [:cmd, cmd]
        unless system(*cmd)
          raise "Error: couldn't send key commands to 'xse'. (Is xsendevents installed?)"
        end
      end

    end # Path.which('xse')

  end # class Window

end
