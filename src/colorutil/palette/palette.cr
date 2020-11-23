require "../color.cr"
require "../relation.cr"

module ColorUtil::Palette
  extend self

  def build(hash : Hash(T, Color | Array(Float64)), relations : Array(Relation))
      : Hash(T, Color) forall T
    # TODO: stub
    return {} of T => Color
  end

  # Shorthand for invoking `Palette::build` without having to create an explicit
  # relationset beforehand. Yields an empty array of `ColorUtil::Relation` in the context
  # of `ColorUtil::Relation`, which allows less verbose construction.
  def build(hash : Hash(T, Color | Array(Float64)),
      &block : Array(Relation) -> Array(Relation))
      : Hash(T, Color) forall T

    relations = with Relation yield [] of Relation
    build(hash, relations)
  end
end
