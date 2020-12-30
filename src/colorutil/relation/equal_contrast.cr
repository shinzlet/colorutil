require "num"
require "./relation.cr"
require "../color.cr"

module ColorUtil::Relations
  # Create a contrast relationship between two keys.
  # `#error` cannot be invoked on an instance until `resolve_keys` has been
  # invoked.
  struct EqualContrast < Relation
    @arguments : Array(UInt32 | Color) | Array(UInt32) | Array(Color)
    @contrast : Float64

    # arguments contains two elements -either indexes into the lightness tensor or color
    # constants, and `constrast` is the WCAG contrast ratio that they should be
    # separated by.
    def initialize(@arguments, @contrast)
    end

    # Returns the squeared contrast error given a lightness tensor.
    def error(lightness : Tensor(Float64)) : Float64
      values = @arguments.map do |arg|
        case arg
        when Color
          # This is a needless recomputation every time. Hopefully i'll fix this
          # someday, but problems similar to this call for a big restructure :(
          arg.approx_relative_luminance
        when UInt32
          lightness[arg].value
        end
      end

      # EqualContrast.error(values[0].not_nil!, values[1].not_nil!, @contrast)
      EqualContrast.error(values[0].not_nil!, values[1].not_nil!, @contrast)
    end

    # Returns the squared difference between the actual and target contrast
    # values.
    def self.error(l1 : Float64, l2 : Float64, contrast : Float64) : Float64
      (contrast - ColorUtil.wcag_contrast(l1, l2)) ** 2
    end

    # TODO: Keep?
    # Returns the largest possible contrast error when a target contrast
    # is provided. The color that causes maximum error will always be either
    # pure white or black.
    def self.max_error(contrast_target)
      Math.max(contrast_target, 21 - contrast_target) ** 2
    end
  end
end
