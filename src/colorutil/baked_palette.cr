require "num"
require "./color"

module ColorUtil
  struct BakedPalette
    ITERATIONS = 500
    VELOCITY = 0.001f64

    @palette : Array(Color)

    # TODO: Implement error caching in constructor
    # getter error : Float64

    def initialize(source : SemanticPalette)
      # Initializing the lightnesses randomly would mean that we'd likely
      # lose temporal coherence - a small change in the driver would create 
      # a large change in the driven colors. This is undesirable, so we'll start
      # at the driver every time to try to keep the solutions in the same neighbourhood
      # of the driver.
      lightness = Tensor(Float64).ones([source.qualia.size + 1]) * source.driver.l

      ITERATIONS.times do
        gradient = BakedPalette.error_gradient(lightness, source.rules)
        # 0 is the driver color, which we won't change.
        gradient[0] = 0
        dynamic_velocity = VELOCITY / (Helpers.norm(gradient)**2 + 1)

        puts "iteration:"
        puts "current lightness: #{lightness}"
        puts "gradient: #{gradient}"
        puts "error: #{BakedPalette.error(lightness, source.rules)}"
        puts "dynamic velocity: #{dynamic_velocity}"
        puts "step: #{gradient * dynamic_velocity}"
        puts
        lightness -= VELOCITY * gradient
        lightness.map! { |value| Math.min(Math.max(value, 0f64), 1f64)}
      end

      # Copy lightness information into a color palette

      @palette = [source.driver]

      source.qualia.each_with_index do |hs, idx|
        @palette << Color.from_hsl(hs[0], hs[1], lightness[idx + 1].value)
      end
    end

    # Returns a tensor of the same size as the input storing the analytic solution for the
    # error gradient in each variable.
    def self.error_gradient(lightness : Tensor(Float64), rules : Array(Array(Float64))) : Tensor(Float64)
      grad = Tensor(Float64).zeros(lightness.shape)

      rules.each do |rule|
        # Compute the partial derivative of the error in each term of the contrast
        # rule.

        2.times do |wrt_idx|
          fixed_idx = wrt_idx ^ 1

          wrt = rule[wrt_idx].to_i32
          fixed = rule[fixed_idx].to_i32

          grad[wrt] += 2 \
            * ( ColorUtil.wcag_contrast(lightness[fixed].value, lightness[wrt].value) - rule[2] ) \
            * d_contrast(lightness[fixed].value, lightness[wrt].value)
        end
      end

      return grad
    end

    def self.error(lightness : Tensor(Float64), rules : Array(Array(Float))) : Float64
      acc = 0f64

      rules.each do |rule|
        acc += (wcag_contrast(lightness[rule[0].to_i32].value, lightness[rule[1].to_i32].value) - rule[2]) ** 2
      end

      return acc
    end

    # Returns the partial derivative of the WCAG contrast function in the variable
    # `wrt` (with respect to) when the other lightness is `fixed`.
    def self.d_contrast(fixed, wrt) : Float64
      if wrt == fixed
        # This might be undesirable, if the system is getting stuck at the inflection point.
        # Consider changing to be a small random number (+/-0.05)
        return 0.05f64
      elsif wrt < fixed
        return -(fixed + 0.05f64) / (wrt + 0.05f64) ** 2
      else
        return 1 / (fixed + 0.05f64)
      end
    end
  end
end
