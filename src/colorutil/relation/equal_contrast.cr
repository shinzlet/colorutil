require "num"
require "./relation.cr"
require "../color.cr"

module ColorUtil
  # Create a contrast relationship between two keys.
  # `#error` cannot be invoked on an instance until `resolve_keys` has been
  # invoked.
  struct EqualContrast(T) < Relation(T)
    property keys : StaticArray(T, 2)
    property resolved_keys : StaticArray(Color | UInt32, 2)?

    # `a` is the first key, `b` is the second key, and `constrast` is the WCAG
    # contrast ratio that they should be separated by.
    def initialize(a : T, b : T, @contrast : Float64)
      @keys = StaticArray[a, b]
    end

    # To prevent repeated key lookups, `resolve_keys` will find either
    # the constant or the lightness tensor index that each key represents.
    def resolve_keys(lookup : Hash(T, UInt32 | Color)) : Nil
      @resolved_keys = keys.map { |key| lookup[key] }
    end

    # Returns the squeared contrast error given a lightness tensor. Raises `NilAssertionError`
    # if `resolve_keys` has not been called.
    def error(lightness : Tensor(Float64)) : Float64
      values = @resolved_keys.not_nil!.map do |key|
        case key
        when Color
          key.approx_relative_luminance
        when UInt32
          lightness[key].value
        end
      end

      EqualContrast.error(values[0].not_nil!, values[1].not_nil!, @contrast)
    end

    # Returns the squared difference between the actual and target contrast
    # values.
    def self.error(l1 : Float64, l2 : Float64, contrast : Float64) : Float64
      (ColorUtil.wcag_contrast(l1, l2) - contrast) ** 2
    end
  end
end
