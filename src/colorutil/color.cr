require "hsluv"

module ColorUtil
  # Specifies a 24 bit color.
  class Color
    getter h : Float64
    getter s : Float64
    getter l : Float64

    # Creates a color from an rgb hexidecimal value. For example,
    # `Color.from_hex(0xff00ff)` creates the fuchsia usually described as
    # "#ff00ff".
    def self.from_hex(color) : Color
      if color > 0xffffff
        color_string = "0x" + color.to_s(16).rjust(6, '0')
        raise OverflowError.new("#{color_string} is not a 24-bit color!")
      end

      r = (color & 0xff0000) >> 16
      g = (color & 0x00ff00) >> 8
      b = (color & 0x0000ff) >> 0

      from_rgb(r, g, b)
    end

    # Creates a `Color` from individual rgb values.
    def self.from_rgb(r, g, b) : Color
      h, s, l = HSLuv.rgb_to_hsluv(r / 255f64, g / 255f64, b / 255f64)
      new(h, s, l)
    end

    # Creates a `Color` using HSLuv hsl components.
    def self.from_hsl(h : Float64, s : Float64, l : Float64) : Color
      new(h, s, l)
    end

    # Generates a random `Color`.
    def self.random : Color
      new(Random.rand(360f64), Random.rand(100f64), Random.rand(100f64))
    end

    # The struct stores data in HSLuv hsl form, so all initializiation eventually
    # boils down to calling this constructor. It's private by default to allow API
    # consistency with from_rgb and from_hsl
    private def initialize(@h, @s, @l)
    end

    def r : UInt8
      rgb[:r]
    end

    def g : UInt8
      rgb[:g]
    end

    def b : UInt8
      rgb[:b]
    end

    def rgb : NamedTuple(r: UInt8, g: UInt8, b: UInt8)
      a = HSLuv.hsluv_to_rgb(@h, @s, @l).map do |val|
        (255 * val).round.clamp(0..255).to_u8
      end

      {r: a[0], g: a[1], b: a[2]}
    end

    def r=(r)
      _, g, b = HSLuv.hsluv_to_rgb(@h, @s, @l)
      @h, @s, @l = HSLuv.rgb_to_hsluv(r, g, b)
    end

    def g=(g)
      r, _, b = HSLuv.hsluv_to_rgb(@h, @s, @l)
      @h, @s, @l = HSLuv.rgb_to_hsluv(r, g, b)
    end

    def b=(b)
      r, g, _ = HSLuv.hsluv_to_rgb(@h, @s, @l)
      @h, @s, @l = HSLuv.rgb_to_hsluv(r, g, b)
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

    # By default, the string version of a color is it's hex string.
    def to_s(io : IO) : Nil
      io << to_hex_string
    end

    # Returns the luminance contrast ratio between this color and another.
    # Computed using WCAG relative luminance.
    def contrast(other : Color) : Float64
      ColorUtil.wcag_contrast(other.relative_luminance, relative_luminance)
    end

    # Returns the luminance contrast ratio between this color and another.
    # Computed using approximate relative luminance.
    # Overall, this function has an error of at most 20% on the exact contrast,
    # but note that this error is much smaller when colors are similar.
    # So, for determining if two colors are readable together, this is
    # likely accurate enough.
    def approx_contrast(other : Color) : Float64
      Color.contrast(other.approx_relative_luminance, self.approx_relative_luminance)
    end

    # Computes the approximate relative luminance of this color.
    # See `ColorUtil#approx_relative_luminance`
    def approx_relative_luminance : Float64
      ColorUtil.approx_relative_luminance(l)
    end

    # Returns the relative luminance of this color, as defined by
    # https://www.w3.org/TR/WCAG20-TECHS/G17.html#G17-tests.
    # This is needed to compute contrast acording to the web content
    # accessibility guidelines.
    def relative_luminance : Float64
      # Transform color channels into luminosity components
      r, g, b = rgb.map do |key, ch|
        ch /= 255f64

        if ch <= 0.03928
          ch /= 12.92
        else
          ch = ((ch + 0.055)/1.055) ** 2.4
        end

        ch
      end

      # Perform a weighted sum of the color channels to match perception
      (r * 0.2126) + (g * 0.7152) + (b * 0.0722)
    end

    # Generates a new color that has a specified contrast ratio to
    # `self`. As contrast ratio is computed only using lightness,
    # this leaves hue and saturation as free parameters which the user
    # can choose.
    def generate(contrast : Float64, hue : Float64, saturation : Float64,
                 min_lightness : Float64 = 0, max_lightness : Float64 = 100) : Color
      min = ColorUtil.approx_relative_luminance(min_lightness)
      max = ColorUtil.approx_relative_luminance(max_lightness)
      rl = self.approx_relative_luminance

      # Predict the needed relative luminance to create the desired contrast,
      # assuming that the generated color should be *lighter* than `self`
      target_rl = contrast * (rl + 5) - 5

      # If the color is outside the bounds of lightness, our assumption (that
      # the generated color would be lighter than `self`) was likely incorrect.
      # Try the opposite case
      unless (min..max).includes? target_rl
        rl_darker = (rl + 5) / contrast - 5

        if (min..max).includes? rl_darker
          target_rl = rl_darker
        else
          # If neither extreme (dark or light) has enough room to provide the desired
          # contrast ratio, we have to just pick the best extreme we can.
          if ColorUtil.wcag_contrast(rl, max) > ColorUtil.wcag_contrast(rl, min)
            target_rl = max
          else
            target_rl = min
          end
        end
      end

      # Convert from WCAG luminance to HSLuv luminance
      luminance = ColorUtil.inverse_approx_relative_luminance(target_rl)

      Color.from_hsl(hue, saturation, luminance)
    end

    # True if and only if each rgb color component is equal among both colors.
    def ==(other : Color) : Bool
      other.h == @h && other.s == @s && other.l == @l
    end
  end
end
