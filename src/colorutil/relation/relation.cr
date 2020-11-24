module ColorUtil
  abstract struct Relation(T)
    abstract def error(lightness : Tensor(Flaot64)) : Float64
  end
end
