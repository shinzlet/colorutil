module ColorUtil::Math
  # Interpolates two values. If `rise` is zero, this returns `a`. If `rise` is one, this returns `b`.
  # For any value in between, this returns the weighted average of the two.
  def interpolate(a, b, rise)
    return a * (1 - rise) + b * rise
  end

  # Given a tensor of rank 2, return the same data structure as a 2D float array.
  def peel_matrix(tensor : Tensor) : Array(Array(Float64))
    Array(Array(Float64)).new(tensor.shape[0]) do |idx|
      tensor[idx].to_a
    end
  end
end
