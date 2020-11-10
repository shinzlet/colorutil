require "yaml"
require "num"
require "./helpers.cr"

include ColorUtil::Helpers

module ColorUtil
  class SemanticPalette
    include YAML::Serializable

    DEFAULT_SIZE = 2
    READABLE_CONTRAST = 3.5f64

    # The driver is the 0th color in a baked keyframe. It is the only fully defined color,
    # and `BakedPalette` uses it as a basis for 
    property driver : Color

    # [[h, s], [h, s], ..] (Hues and saturations for each foreground color, starting at color 1
    property qualia : Array(Array(Float64))

    # [[color1, color2, contrast], ...] (Pairs of color indecies and the contrast between them)
    property rules : Array(Array(Float64))

    def initialize(@driver, @qualia, @rules)
    end

    def initialize()
      # Define the driver color to be black
      @driver = Color.from_hsl(0f64, 0f64, 0f64)

      # Make colors fully saturated and a rainbow in their indeces
      @qualia = Array(Array(Float64)).new(DEFAULT_SIZE - 1) do |i|
        [(360f64 * i) / (DEFAULT_SIZE-1), 50f64]
      end

      # Create a rule that forces each color to have a readable contrast with the driver.
      @rules = Array(Array(Float64)).new(DEFAULT_SIZE - 1) do |i|
        [0f64, i + 1f64, READABLE_CONTRAST]
      end
    end

    # TODO: Rename variables to start and stop
    # Create a new keyframe via the interpolation of the previous ans subsequent keyframe.
    def initialize(prev, subs, rise)
      @driver = interpolate(prev.driver.to_tensor, subs.driver.to_tensor, rise).to_a
      @qualia = peel_matrix(interpolate(prev.qualia.to_tensor, subs.quala.to_tensor, rise))
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

    # Returns a `BakedPalette` instantiated with this semantic information
    def bake : BakedPalette
      BakedPalette.new(self)
    end
  end
end
