module Mixologist::Utils
  # Given an array of sorted values and a target, this function will return the
  # largest index that `target` could be inserted before while keeping the
  # array sorted.  If `target` is greater than any other value in the array,
  # this index will equal `sorted_values.size`.
  def insertion_point(target, sorted_values) : Int32
    sorted_values.bsearch_index { |value| value > target } || sorted_values.size
  end

  # Returns the minimum increment such that `start + modular_difference(start,
  # stop, base)` is congruent to `stop` mod `base`
  def modular_difference(start, stop, base)
    # Rotate the clock so that `start` is at zero.  This has the result of
    # shifting `stop` to rest on the value of the difference between the two
    # points.
    shift = base - start

    return (stop + shift) % base
  end

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
