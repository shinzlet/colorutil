require "yaml"
require "num"
require "./utils.cr"

include Mixologist::Utils

module Mixologist
  class SemanticPalette
    include YAML::Serializable

    DEFAULT_SIZE = 3
    READABLE_CONTRAST = 3.5f64

    # [h, s, l] triple
    property driver : Array(Float64)

    # [[h, s], [h, s], ..] (Hues and saturations for each foreground color, starting at 1
    property colors : Array(Array(Float64))

    # [[color1, color2, contrast], ...] (Pairs of color indecies and the contrast between them)
    property rules : Array(Array(Float64))

    def initialize(@bg, @fg, @rules)
    end

    def initialize()
      # Initialize the background to black
      @bg = [1f64, 2f64, 3f64]
      
      # Make all the foreground colors fully saturated and a rainbow in their indeces
      @fg = Array(Array(Float64)).new(FG_COLORS) do |i|
        [(360f64 * i) / (FG_COLORS), 50f64]
      end

      @rules = Array(Array(Float64)).new(PALETTE_SIZE - 1) do |i|
        [0f64, i + 1f64, READABLE_CONTRAST]
      end
    end

    # Create a new keyframe via the interpolation of the previous ans subsequent keyframe.
    def initialize(prev, subs, rise)
      @bg = interpolate(prev.bg.to_tensor, subs.bg.to_tensor, rise).to_a
      @fg = peel_matrix(interpolate(prev.fg.to_tensor, subs.fg.to_tensor, rise))
      interpolated_contrast_tensor = interpolate(prev.contrast_tensor, subs.contrast_tensor, rise)
      @rules = BakedPalette.construct_rules(interpolated_contrast_tensor)
    end


    # Returns a square matrix with `PALETTE_SIZE` rows. The value at the index `(i, j)` is
    # the contrast between color `i` and color `j`. If the contrast between the two is zero,
    # there is no contrast rule for the pair `(i, j)`.
    def contrast_tensor : Tensor(Float64)
      ret = Tensor(Float64).identity(PALETTE_SIZE)

      @rules.each do |rule|
        ret[rule[0].to_i32, rule[1].to_i32] = rule[2]
        ret[rule[1].to_i32, rule[0].to_i32] = rule[2]
      end

      ret
    end

    # Rebuilds a set of rules given a contrast tensor.
    def self.construct_rules(tensor : Tensor) : Array(Array(Float64))
      rules = [] of Array(Float64)

      # Iterate over all elements below the diagonal (the tensor is symmetric)
      (1...PALETTE_SIZE).each do |i|
        (0...i).each do |j|

          if tensor[i, j].value != 0
            rules << [i.to_f64, j.to_f64, tensor[i, j].value]
          end
        end
      end

      rules
    end
  end
end
