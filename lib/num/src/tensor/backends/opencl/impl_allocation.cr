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

class OCL(T) < Num::Backend::Storage(T)
  # Initialize an OpenCL storage from an initial capacity.
  # The data will be filled with zeros
  #
  # ## Arguments
  #
  # * shape : `Array(Int)` - Shape for parent `Tensor`
  # * order : `Num::OrderType` - Memory layout for parent `Tensor`
  #
  # ## Examples
  #
  # ```
  # OCL.new([100], Num::RowMajor)
  # ```
  def initialize(shape : Array(Int), order : Num::OrderType)
    @data = Cl.buffer(Num::ClContext.instance.context, shape.product.to_u64, dtype: T)
    @shape = metadata_to_buffer(shape.map &.to_i)
    @strides = metadata_to_buffer(Num::Internal.shape_to_strides(shape, order))
    @total_size = shape.product
  end

  # Initialize an OpenCL storage from an initial capacity.
  # The data will be filled with zeros
  #
  # ## Arguments
  #
  # * shape : `Array(Int)` - Shape for parent `Tensor`
  # * strides : `Array(Int)` - Strides for parent `Tensor`
  #
  # ## Examples
  #
  # ```
  # OCL.new([100], [1])
  # ```
  def initialize(shape : Array(Int), strides : Array(Int))
    @data = Cl.buffer(Num::ClContext.instance.context, shape.product.to_u64, dtype: T)
    @shape = metadata_to_buffer(shape.map &.to_i)
    @strides = metadata_to_buffer(strides.map &.to_i)
    @total_size = shape.product
  end

  # Initialize an OpenCL storage from an initial capacity and
  # an initial value, which will fill the buffer
  #
  # ## Arguments
  #
  # * shape : `Array(Int)` - Shape for parent `Tensor`
  # * order : `Num::OrderType` - Memory layout for parent `Tensor`
  # * value : `T` - Value to initially populate the buffer
  #
  # ## Examples
  #
  # ```
  # OCL.new([10, 10], Num::RowMajor, 3.4)
  # ```
  def initialize(shape : Array(Int), order : Num::OrderType, value : T)
    @data = Cl.buffer(Num::ClContext.instance.context, shape.product.to_u64, dtype: T)
    @shape = metadata_to_buffer(shape.map &.to_i)
    @strides = metadata_to_buffer(Num::Internal.shape_to_strides(shape, order))
    @total_size = shape.product
    Cl.fill(Num::ClContext.instance.queue, @data, value, shape.product.to_u64)
  end

  # Initialize an OpenCL storage from an initial capacity and
  # an initial value, which will fill the buffer
  #
  # ## Arguments
  #
  # * shape : `Array(Int)` - Shape for parent `Tensor`
  # * strides : `Array(Int)` - Strides for parent `Tensor`
  # * value : `T` - Value to initially populate the buffer
  #
  # ## Examples
  #
  # ```
  # OCL.new([10, 10], [10, 1], 3.4)
  # ```
  def initialize(shape : Array(Int), strides : Array(Int), value : T)
    @data = Cl.buffer(Num::ClContext.instance.context, shape.product.to_u64, dtype: T)
    @shape = metadata_to_buffer(shape.map &.to_i)
    @strides = metadata_to_buffer(strides.map &.to_i)
    @total_size = shape.product
    Cl.fill(Num::ClContext.instance.queue, @data, value, shape.product.to_u64)
  end

  # Initialize an OpenCL storage from a standard library Crystal
  # pointer
  #
  # ## Arguments
  #
  # * hostptr : `Pointer(T)` - Stdlib Crystal pointer containing the `Tensor`s
  #   data
  # * shape : `Array(Int)` - Shape for parent `Tensor`
  # * strides : `Array(Int)` - Strides for parent `Tensor`
  #
  # ## Examples
  #
  # ```
  # ptr = Pointer(Int32).malloc(9)
  # OCL.new(ptr, [3, 3], [3, 1])
  # ```
  def initialize(hostptr : Pointer(T), shape : Array(Int), strides : Array(Int))
    @data = Cl.buffer(Num::ClContext.instance.context, shape.product.to_u64, dtype: T)
    @shape = metadata_to_buffer(shape.map &.to_i)
    @strides = metadata_to_buffer(strides.map &.to_i)
    @total_size = shape.product
    Cl.write(Num::ClContext.instance.queue, hostptr, @data, (shape.product * sizeof(T)).to_u64)
  end

  def update_metadata(shape : Array(Int32), strides : Array(Int32))
    @shape = metadata_to_buffer(shape)
    @strides = metadata_to_buffer(strides)
  end

  # Return a generic class of a specific generic type, to allow
  # for explicit return types in functions that return a different
  # storage type than the parent Tensor
  #
  # ```
  # a = OCL(Float32).new([10])
  #
  # # Cannot do
  # # a.class.new ...
  #
  # a.class.base(Float64).new([10])
  # ```
  def self.base(dtype : U.class) : OCL(U).class forall U
    OCL(U)
  end

  private def metadata_to_buffer(arr : Array(Int32))
    buffer = Cl.buffer(Num::ClContext.instance.context, arr.size.to_u64, dtype: Int32)
    Cl.write(Num::ClContext.instance.queue, arr.to_unsafe, buffer, (arr.size * sizeof(Int32)).to_u64)
    buffer
  end

  # Releases the underlying `LibCL::ClMem` buffers containing the
  # data for a `Tensor`, as well as the buffers containing the
  # shape and strides for the `Tensor`
  def finalize
    Cl.release_buffer(@data)
    Cl.release_buffer(@shape)
    Cl.release_buffer(@strides)
  end
end
