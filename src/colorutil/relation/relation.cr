require "num"

module ColorUtil::Relations
  abstract struct Relation
    abstract def error(lightness : Tensor(Float64)) : Float64
  end
end
