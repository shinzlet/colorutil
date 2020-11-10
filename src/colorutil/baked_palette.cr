require "num"
require "./color"

module Colorutil
  struct BakedPalette
    ITERATIONS = 20
    VELOCITY = 0.5f64

    @palette : Array(Color)
    getter error : Float64

    def initialize(source : BakedPalette)
      # Initializing the lightnesses randomly would mean that we'd likely
      # lose temporal coherence - a small change in the driver would create 
      # a large change in the driven colors. This is undesirable, so we'll start
      # at the driver every time to try to keep the solutions in the same neighbourhood
      # of the driver.
      lightness = Tensor(Float64).ones([source.size]) * source.driver.l

      ITERATIONS.times do
        gradient = error_gradient(lightness, source.rules)
        lightness -= VELOCITY * gradient
      end
    end

    # Returns a tensor of the same size as the input storing the analytic solution for the
    # error gradient in each variable.
    def error_gradient(lightness : Tensor(Float64), rules : Array(Float64))
      grad = Tensor(Float64).zeros(palette.size)

      rules.each do |rule|
        # Compute the partial derivative of the error in each term of the contrast
        # rule.

        2.times do |wrt_idx|
          fixed_idx = wrt_idx ^ 1

          wrt = rule[wrt_idx]
          fixed = rule[fixed_idx]

          grad[wrt] += 2 \
            * ( ColorUtil.wcag_contrast(lightness[fixed], lightness[wrt]) - rule[2] ) \
            * d_contrast(lightness[fixed], lightness[wrt])
        end
      end

      return grad
    end

    # Returns the partial derivative of the WCAG contrast function in the variable
    # `wrt` (with respect to) when the other lightness is `fixed`.
    def d_contrast(fixed, wrt)
      if wrt == fixed
        # This might be undesirable, if the system is getting stuck at the inflection point.
        # Consider changing to be a small random number (+/-0.05)
        return 0
      elsif wrt < fixed
        return -(fixed + 0.05f64) / (wrt + 0.05f64) ** 2
      else
        return 1 / (fixed + 0.05f64)
      end
    end
  end
end
