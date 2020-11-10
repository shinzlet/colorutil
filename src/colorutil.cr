require "./colorutil/*"

# TODO: Write documentation for `Colorutil`
module ColorUtil
  extend self
  VERSION = "0.1.0"

  # Returns the WCAG contrast ratio between two colors.
  #
  # Parameters:
  # 	the relative luminosities of both colors.
  def wcag_contrast(rl_1 : Float64, rl_2 : Float64) : Float64
    return (0.05 + Math.max(rl_1, rl_2)) / (0.05 + Math.min(rl_1, rl_2))
  end

  # Returns an approximation of the relative luminance of this color.
  # Computing the actual relative luminance requires undergoing a color
  # transformation into rgb before computing - this isn't incredibly
  # computationally expensive (<1ms), but this function returns very
  # similar values with only a few mathematical operators.
  # This transformation only utilizes the l component of an HSLuv color,
  # and is one to one, meaning that it's invertible.
  #
  # The error is about +/- 0.03 from the exact relative luminance, but this code runs
  # ~200x faster.
  # (See Color#inverse_approx_relative_luminance)
  def approx_relative_luminance(l_hsluv) : Float64
    (l_hsluv / 100f64) ** 2.4
  end

  # Converts a color's approximate relative luminance back into HSLuv luminance.
  def inverse_approx_relative_luminance(l_wcag) : Float64
    100 * ((l_wcag) ** (1 / 2.4))
  end
end
