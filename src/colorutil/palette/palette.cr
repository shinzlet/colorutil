require "../color.cr"
require "../relation/*"

include ColorUtil::Relations

module ColorUtil::Palette
  extend self

  # Converts a semantic description of a color palette into actual colors.
  #
  # Parameters:
  #   basis: A hash connecting a ColorUtil::Color or a
  #          partial color (a two-element float array describing hue and saturation)
  #          to an identifier. These very same keys will be used in the return hash.
  #   relations: An array of relations between colors. Note that relations require
  #              integer indexes, not hash keys - see `#create_lookup` or the other
  #              definition of `#build` for more on how to create this.
  # 
  # Returns an approximate solution of the provided color constraints using
  # default parameters. Only partial colors will be optimized - if `basis[:a}` is
  # a `Color`, then `build(basis, relations)[:a}` will be that very same color.
  def build(basis : Hash(K, Optimizer::AnyColor),
            relations : Array(ColorUtil::Relations::Relation)) : Hash(K, Color) forall K
    lookup = create_lookup(basis)
    bundle(basis, lookup, Optimizer.optimize(lookup, relations))
  end

  # Shorthand for invoking `Palette::build` without having to create an explicit
  # relationset beforehand. Yields an empty array of `ColorUtil::Relation` in the
  # context of the `Relations` module, which allows code to be much more terse.
  # This array does not need to be returned - all modifications are tracked.
  def build(basis : Hash(K, Optimizer::AnyColor), &block) : Hash(K, Color) forall K
    lookup, variable_count = create_lookup(basis)
    relations = [] of Relation
    with Relations yield relations, lookup

    bundle(basis, lookup, Optimizer.optimize(lookup, relations))
  end

  # Converts a map whos values are `Optimizer::AnyColor` into 
  def create_lookup(basis : Hash(K, Optimizer::AnyColor)) : {Hash(K, UInt32 | Color), UInt32} forall K
    keys = basis.keys

    # Decompose `basis` into a more useful representation
    lookup = Hash(K, UInt32 | Color).new(initial_capacity: keys.size)
    variable_count = 0u32

    keys.each do |key|
      value = basis[key]

      if value.is_a? Color
        lookup[key] = value
      else
        lookup[key] = variable_count
        variable_count += 1
      end
    end
    
    return {lookup, variable_count}
  end

  # Converts optimization data into a user-friendly color palette.
  def bundle(basis : Hash(K, Optimizer::AnyColor), lookup, lightness) : Hash(K, Color) forall K
    output = Hash(K, Color).new(initial_capacity: basis.size)

    lookup.each do |key, val|
      case val
      when UInt32
        hs = basis[key].as(Array(Float64))
        l = ColorUtil.inverse_approx_relative_luminance(lightness[val].value)
        output[key] = Color.from_hsl(hs[0], hs[1], l)
      when Color
        output[key] = val
      end
    end

    output
  end
end
