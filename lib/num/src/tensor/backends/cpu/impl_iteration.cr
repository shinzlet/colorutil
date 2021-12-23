# Copyright (c) 2020 Crystal Data Contributors
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Num
  extend self

  # Yields the elements of a `Tensor`, always in RowMajor order,
  # as if the `Tensor` was flat.
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` from which values will be yielded
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new(2, 2) { |i| i }
  # a.each do |el|
  #   puts el
  # end
  #
  # # 0
  # # 1
  # # 2
  # # 3
  # ```
  @[AlwaysInline]
  def each(arr : Tensor(U, CPU(U)), &block : U -> _) forall U
    each_pointer_with_index(arr) do |el, _|
      yield el.value
    end
  end

  # Yields the elements of two `Tensor`s, always in RowMajor order,
  # as if the `Tensor`s were flat.
  #
  # ## Arguments
  #
  # * a : `Tensor(U, CPU(U))` - First `Tensor` of iteration
  # * b : `Tensor(U, CPU(U))` - Second `Tensor` of iteration
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new(2, 2) { |i| i }
  # b = Tensor.new(2, 2) { |i| i + 2 }
  # a.zip(b) do |el|
  #   puts el
  # end
  #
  # # { 0, 2}
  # # { 1, 3}
  # # { 2, 4}
  # # { 3, 5}
  # ```
  @[AlwaysInline]
  def zip(a : Tensor(U, CPU(U)), b : Tensor(V, CPU(V)), &block : U, V -> _) forall U, V
    a, b = a.broadcast(b)
    Num::Backend.dual_strided_iteration(a, b) do |idx, i, j|
      yield i.value, j.value
    end
  end

  # Yields the elements of a `Tensor` lazily, always in RowMajor order,
  # as if the `Tensor` was flat.
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` from which to create an iterator
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new(2, 2) { |i| i }
  # iter = a.each
  # a.size.times do
  #   puts iter.next.value
  # end
  #
  # # 0
  # # 1
  # # 2
  # # 3
  # ```
  @[AlwaysInline]
  def each(arr : Tensor(U, CPU(U))) forall U
    Num::Internal::UnsafeNDFlatIter.new(arr)
  end

  # Yields the memory locations of each element of a `Tensor`, always in
  # RowMajor oder, as if the `Tensor` was flat.
  #
  # This should primarily be used by internal methods.  Methods such
  # as `map!` provided more convenient access to editing the values
  # of a `Tensor`
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` from which values will be yielded
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new(2, 2) { |i| i }
  # a.each_pointer do |el|
  #   puts el.value
  # end
  #
  # # 0
  # # 1
  # # 2
  # # 3
  # ```
  @[AlwaysInline]
  def each_pointer(arr : Tensor(U, CPU(U)), &block : Pointer(U) -> _) forall U
    each_pointer_with_index(arr) do |el, _|
      yield el
    end
  end

  # Yields the elements of a `Tensor`, always in RowMajor order,
  # as if the `Tensor` was flat.  Also yields the flat index of each
  # element.
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` from which values will be yielded
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new(2, 2) { |i| i }
  # a.each_with_index do |el, i|
  #   puts "#{el}_#{i}"
  # end
  #
  # # 0_0
  # # 1_1
  # # 2_2
  # # 3_3
  # ```
  @[AlwaysInline]
  def each_with_index(arr : Tensor(U, CPU(U)), &block : U, Int32 -> _) forall U
    each_pointer_with_index(arr) do |el, i|
      yield el.value, i
    end
  end

  # Yields the memory locations of each element of a `Tensor`, always in
  # RowMajor oder, as if the `Tensor` was flat.
  #
  # This should primarily be used by internal methods.  Methods such
  # as `map!` provided more convenient access to editing the values
  # of a `Tensor`
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` from which values will be yielded
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new(2, 2) { |i| i }
  # a.each_pointer do |el|
  #   puts el.value
  # end
  #
  # # 0
  # # 1
  # # 2
  # # 3
  # ```
  @[AlwaysInline]
  def each_pointer_with_index(arr : Tensor(U, CPU(U)), &block : Pointer(U), Int32 -> _) forall U
    Num::Backend.strided_iteration(arr) do |i, el|
      yield el, i
    end
  end

  # Maps a block across a `Tensor`.  The `Tensor` is treated
  # as flat during iteration, and iteration is always done
  # in RowMajor order
  #
  # The generic type of the returned `Tensor` is inferred from
  # the block
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` to map the `Proc` across
  # * block : `Proc(T, U)` - Proc to map across the `Tensor`
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3]) { |i| i }
  # a.map { |e| e + 5 } # => [5, 6, 7]
  # ```
  @[AlwaysInline]
  def map(arr : Tensor(U, CPU(U)), &block : U -> V) : Tensor(V, CPU(V)) forall U, V
    result = Tensor(V, CPU(V)).new(arr.shape)
    data = result.data.to_hostptr
    each_with_index(arr) do |el, i|
      data[i] = yield el
    end
    result
  end

  # Maps a block across a `Tensor` in place.  The `Tensor` is treated
  # as flat during iteration, and iteration is always done
  # in RowMajor order
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` to map the `Proc` across
  # * block : `Proc(T, U)` - Proc to map across the `Tensor`
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3]) { |i| i }
  # a.map! { |e| e + 5 }
  # a # => [5, 6, 7]
  # ```
  @[AlwaysInline]
  def map!(arr : Tensor(U, CPU(U)), &block : U -> _) forall U
    each_pointer(arr) do |ptr|
      value = yield(ptr.value)
      {% if U == Bool %}
        ptr.value = (value ? true : false) && value != 0
      {% elsif U == String %}
        ptr.value = value.to_s
      {% else %}
        ptr.value = U.new(value)
      {% end %}
    end
  end

  # Maps a block across two `Tensors`.  This is more efficient than
  # zipping iterators since it iterates both `Tensor`'s in a single
  # call, avoiding overhead from tracking multiple iterators.
  #
  # The generic type of the returned `Tensor` is inferred from a block
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - First `Tensor` for iteration, must be
  #   broadcastable against the shape of a1
  # * a1 : `Tensor(V, CPU(V))` - Second `Tensor` for iteration, must be
  #   broadcastable against the shape of a0
  # * block : `Proc(T, U, V)` - The block to map across both `Tensor`s
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3]) { |i| i }
  # b = Tensor.new([3]) { |i| i }
  #
  # a.map(b) { |i, j| i + j } # => [0, 2, 4]
  # ```
  @[AlwaysInline]
  def map(a0 : Tensor(U, CPU(U)), a1 : Tensor(V, CPU(V)), &block : U, V -> W) forall U, V, W
    a0, a1 = a0.broadcast(a1)
    result = Tensor(W, CPU(W)).new(a0.shape)
    data = result.data.to_hostptr
    Num::Backend.dual_strided_iteration(a0, a1) do |index, a, b|
      data[index] = yield a.value, b.value
    end
    result
  end

  # Maps a block across two `Tensors`.  This is more efficient than
  # zipping iterators since it iterates both `Tensor`'s in a single
  # call, avoiding overhead from tracking multiple iterators.
  # The result of the block is stored in `self`.
  #
  # Broadcasting rules still apply, but since this is an in place
  # operation, the other `Tensor` must broadcast to the shape of `self`
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - First `Tensor` for iteration
  # * a1 : `Tensor(V, CPU(V))` - Second `Tensor` for iteration, must be
  #   broadcastable against the shape of a0
  # * block : `Proc(T, U, V)` - The block to map across both `Tensor`s
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3]) { |i| i }
  # b = Tensor.new([3]) { |i| i }
  #
  # a.map!(b) { |i, j| i + j }
  # a # => [0, 2, 4]
  # ```
  @[AlwaysInline]
  def map!(a0 : Tensor(U, CPU(U)), a1 : Tensor(V, CPU(V)), &block : U, V -> _) forall U, V
    a1 = a1.broadcast_to(a0.shape)
    Num::Backend.dual_strided_iteration(a0, a1) do |_, i, j|
      value = yield(i.value, j.value)
      {% if U == Bool %}
        i.value = (value ? true : false) && value != 0
      {% elsif U == String %}
        i.value = value.to_s
      {% else %}
        i.value = U.new(value)
      {% end %}
    end
  end

  # Maps a block across three `Tensors`.  This is more efficient than
  # zipping iterators since it iterates all `Tensor`'s in a single
  # call, avoiding overhead from tracking multiple iterators.
  #
  # The generic type of the returned `Tensor` is inferred from a block
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - First `Tensor` for iteration, must be
  #   broadcastable against the shape of a1 and a2
  # * a1 : `Tensor(V, CPU(V))` - Second `Tensor` for iteration, must be
  #   broadcastable against the shape of a0 and a2
  # * a2 : `Tensor(W, CPU(W))` - Third `Tensor` for iteration, must be
  #   broadcastable against the shape of a0 and a1
  # * block : `Proc(T, U, V)` - The block to map across both `Tensor`s
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3]) { |i| i }
  # b = Tensor.new([3]) { |i| i }
  # c = Tensor.new([3]) { |i| i }
  #
  # a.map(b, c) { |i, j, k| i + j + k } # => [0, 3, 6]
  # ```
  @[AlwaysInline]
  def map(
    a0 : Tensor(U, CPU(U)),
    a1 : Tensor(V, CPU(V)),
    a2 : Tensor(W, CPU(W)),
    &block : U, V, W -> X
  ) : Tensor(X, CPU(X)) forall U, V, W, X
    a0, a1, a2 = a0.broadcast(a1, a2)
    result = Tensor(X, CPU(X)).new(a0.shape)
    data = result.data.to_hostptr
    Num::Backend.tri_strided_iteration(a0, a1, a2) do |index, i, j, k|
      data[index] = yield i.value, j.value, k.value
    end
    result
  end

  # Maps a block across three `Tensors`.  This is more efficient than
  # zipping iterators since it iterates all `Tensor`'s in a single
  # call, avoiding overhead from tracking multiple iterators.
  # The result of the block is stored in `self`.
  #
  # Broadcasting rules still apply, but since this is an in place
  # operation, the other `Tensor`'s must broadcast to the shape of `self`
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - First `Tensor` for iteration
  # * a1 : `Tensor(V, CPU(V))` - Second `Tensor` for iteration, must be
  #   broadcastable against the shape of a0
  # * a2 : `Tensor(W, CPU(W))` - Third `Tensor` for iteration, must be
  #   broadcastable against the shape of a0
  # * block : `Proc(T, U, V)` - The block to map across both `Tensor`s
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3]) { |i| i }
  # b = Tensor.new([3]) { |i| i }
  # c = Tensor.new([3]) { |i| i }
  #
  # a.map!(b, c) { |i, j, k| i + j + k }
  # a # => [0, 3, 6]
  # ```
  @[AlwaysInline]
  def map!(a0 : Tensor(U, CPU(U)), a1 : Tensor(V, CPU(V)), a2 : Tensor(W, CPU(W)), &block) forall U, V, W
    a1 = a1.broadcast_to(a0.shape)
    a2 = a2.broadcast_to(a2.shape)
    Num::Backend.tri_strided_iteration(a0, a1, a2) do |_, i, j, k|
      value = yield(i.value, j.value, k.value)
      {% if U == Bool %}
        i.value = (value ? true : false) && value != 0
      {% elsif U == String %}
        i.value = value.to_s
      {% else %}
        i.value = U.new(value)
      {% end %}
    end
  end

  # :nodoc:
  @[AlwaysInline]
  private def at_axis_index(
    a : Tensor(U, V),
    axis : Int,
    index : Int,
    dims : Bool = false
  ) forall U, V
    shape, strides, offset = a.shape.dup, a.strides.dup, a.offset
    if dims
      shape[axis] = 1
      strides[axis] = 1
    else
      shape.delete_at(axis)
      strides.delete_at(axis)
    end
    offset += a.strides[axis] * index
    Tensor(U, V).new(a.data, shape, strides, offset)
  end

  # :nodoc:
  @[AlwaysInline]
  def normalize_axis_index(axis : Int, rank : Int)
    axis = rank + axis if axis < 0
    raise "Axis out of range for Tensor" if axis >= rank
    return axis
  end

  # Reduces a `Tensor` along an axis. Returns a `Tensor`, with the axis
  # of reduction either removed, or reduced to 1 if `dims` is True, which
  # allows the result to broadcast against its previous shape
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - `Tensor` to reduce along an axis
  # * axis : `Int` - Axis of reduction
  # * dims : `Bool` - Flag determining whether the axis of reduction should be
  #   kept in the result
  # * block : `Proc(U, U, _)` - `Proc` to apply to values along an axis
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([2, 2]) { |i| i }
  # a.reduce_axis(0) { |i, j| i + j } # => [2, 4]
  # ```
  @[AlwaysInline]
  def reduce_axis(a0 : Tensor(U, CPU(U)), axis : Int, dims : Bool = false, &block : U, U -> _) forall U
    axis = normalize_axis_index(axis, a0.rank)
    result = at_axis_index(a0, axis, 0, dims).dup
    1.step(to: a0.shape[axis] - 1) do |i|
      result.map!(at_axis_index(a0, axis, i, dims)) do |i, j|
        yield i, j
      end
    end
    result
  end

  # Yields a view of each lane of an `axis`.  Changes made in
  # the passed block will be reflected in the original `Tensor`
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - `Tensor` to iterate along
  # * axis : `Int` - Axis of reduction
  # * dims : `Bool` - Indicates if the axis of reduction should be removed
  #   from the result
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3, 3]) { |i| i }
  # a.each_axis(1) do |ax|
  #   puts ax
  # end
  #
  # # [0, 3, 6]
  # # [1, 4, 7]
  # # [2, 5, 8]
  # ```
  @[AlwaysInline]
  def each_axis(a0 : Tensor(U, CPU(U)), axis : Int, dims : Bool = false, &block : Tensor(U, CPU(U)) -> _) forall U
    axis = normalize_axis_index(axis, a0.rank)
    0.step(to: a0.shape[axis] - 1) do |i|
      yield at_axis_index(a0, axis, i, dims)
    end
  end

  # Returns an iterator along each element of an `axis`.
  # Each element returned by the iterator is a view, not a copy
  #
  # ## Arguments
  #
  # * arr : `Tensor(U, CPU(U))` - `Tensor` to iterate along
  # * axis : `Int` - Axis of reduction
  # * dims : `Bool` - Indicates if the axis of reduction should be removed
  #   from the result
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3, 3]) { |i| i }
  # a.each_axis(1).next # => [0, 3, 6]
  # ```
  @[AlwaysInline]
  def each_axis(arr : Tensor(U, CPU(U)), axis : Int, dims : Bool = false) forall U
    Num::Internal::UnsafeAxisIter.new(arr, axis, dims)
  end

  # Similar to `each_axis`, but instead of yielding slices of
  # an axis, it yields slices along an axis, useful for methods
  # that require an entire view of an `axis` slice for a reduction
  # operation, such as `std`, rather than being able to incrementally
  # reduce.
  #
  # ## Arguments
  #
  # * a0 : `Tensor(U, CPU(U))` - `Tensor` along which to iterate
  # * axis : `Int` - Axis of reduction
  #
  # ## Examples
  #
  # ```
  # a = Tensor.new([3, 3, 3]) { |i| i }
  # a.yield_along_axis(0) do |ax|
  #   puts ax
  # end
  #
  # # [ 0,  9, 18]
  # # [ 1, 10, 19]
  # # [ 2, 11, 20]
  # # [ 3, 12, 21]
  # # [ 4, 13, 22]
  # # [ 5, 14, 23]
  # # [ 6, 15, 24]
  # # [ 7, 16, 25]
  # # [ 8, 17, 26]
  # ```
  @[AlwaysInline]
  def yield_along_axis(a0 : Tensor(U, CPU(U)), axis : Int) forall U
    axis = normalize_axis_index(axis, a0.rank)
    nd = a0.rank
    dims = (0...nd).to_a
    view = a0.transpose(dims[...axis] + dims[axis + 1...] + [axis])

    buf = Tensor(U, CPU(U)).new(view.shape)
    buf_permute = (
      dims[...axis] +
      dims[(nd - 1)...nd] +
      dims[axis...(nd - 1)]
    )

    indices = Num::Internal::NDIndex.new(view.shape[...-1])
    indices.each do |ind|
      yield view[ind]
    end
  end
end
