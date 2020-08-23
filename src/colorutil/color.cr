require "hsluv"

module ColorUtil
  # Specifies a 24 bit color.
  struct Color
    getter h : Float64
    getter s : Float64
    getter l : Float64

    # Creates a color from an rgb hexidecimal value. For example,
    # `Color.from_hex(0xff00ff)` creates the fuchsia usually described as
    # "#ff00ff".
    def self.from_hex(color)
      if color > 0xffffff
        color_string = "0x" + color.to_s(16).rjust(6, '0')
        raise OverflowError.new("#{color_string} is not a 24-bit color!")
      end

      r = (color & 0xff0000) >> 16
      g = (color & 0x00ff00) >> 8
      b = (color & 0x0000ff) >> 0

      from_rgb(r, g, b)
    end

    # Creates a color from individual rgb values.
    def self.from_rgb(r, g, b)
      h, s, l = HSLuv.rgb_to_hsluv(r.to_f64, g.to_f64, b.to_f64)
      new(h, s, l)
    end

    # The struct stores data in HSLuv hsl form, so all initializiation eventually
    # boils down to calling this constructor.
    private def initialize(@h, @s, @l)
    end

    def r
    end

    def g
    end

    def b
    end

    # Returns the raw 24-bit integer value that represents this color.
    # For example, pure blue (0x0000ff) would return the integer 255.
    # This is effectively the inverse to the constructor "from_hex".
    def to_hex : UInt32
      ((r.to_u32 << 16) + (g.to_u32 << 8) + (b.to_u32 << 0)).to_u32
    end

    # Returns a human readable hex color code - e.g. "#ff00ff" for pure fuchsia.
    def to_hex_string : String
      HSLuv.hsluv_to_hex(@h, @s, @l)
    end

    # True if and only if each rgb color component is equal among both colors.
    def ==(other : Color) : Bool
      other.h == @h && other.s == @s && other.l == @l
    end
  end
end
