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

class Tensor(T, S)
  include Enumerable(T)

  getter data : S

  # Returns the size of a Tensor along each dimension
  #
  # ## Examples
  #
  # ```
  # a = Tensor(Int8, CPU(Int8)).new([2, 3, 4])
  # a.shape # => [2, 3, 4]
  # ```
  getter shape : Array(Int32)

  # Returns the step of a Tensor along each dimension
  #
  # ## Examples
  #
  # ```
  # a = Tensor(Int8, CPU(Int8)).new([3, 3, 2])
  # a.shape # => [4, 2, 1]
  # ```
  getter strides : Array(Int32)

  # Returns the offset of a Tensor's data
  #
  # ## Examples
  #
  # ```
  # a = Tensor(Int8, CPU(Int8)).new([2, 3, 4])
  # a.offset # => 0
  # ```
  getter offset : Int32

  # Returns the size of a Tensor along each dimension
  #
  # ```
  # a = Tensor(Int8, CPU(Int8)).new([2, 3, 4])
  # a.shape # => [2, 3, 4]
  # ```
  getter size : Int32

  # Returns the flags of a Tensor, describing its memory
  # and read status
  #
  # ## Examples
  #
  # ```
  # a = Tensor(Float32, CPU(Float32)).new([2, 3, 4])
  # b = a[..., 1]
  # a.flags # => CONTIGUOUS | OWNDATA | WRITE
  # b.flags # => WRITE
  # ```
  getter flags : Num::ArrayFlags

  # Returns the number of dimensions in a Tensor
  #
  # ## Examples
  #
  # ```
  # a = Tensor(Int8, CPU(Int8)).new([3, 3, 3, 3])
  # a.rank # => 4
  # ```
  def rank : Int32
    @shape.size
  end

  # :nodoc:
  def to_s(io)
    io << to_s
  end

  # :nodoc:
  def to_s : String
    Num.tensor_to_string(self)
  end

  # :nodoc:
  def to_unsafe
    @data.to_unsafe
  end

  # :nodoc:
  def to_tensor
    self
  end

  # :nodoc:
  def get_offset_ptr
    self.to_unsafe + self.offset
  end

  # :nodoc:
  def get_offset_ptr_c
    {% if T == Complex %}
      self.get_offset_ptr.as(LibCblas::ComplexDouble*)
    {% else %}
      self.get_offset_ptr
    {% end %}
  end

  private macro assert_types
    {% if T != S.type_vars[0] %}
      {% raise "A Tensor and it's storage must share the same dtype" %}
    {% end %}
  end

  # :nodoc:
  def is_f_contiguous : Bool
    return true unless self.rank != 0
    if self.rank == 1
      return @shape[0] == 1 || @strides[0] == 1
    end
    s = 1
    self.rank.times do |i|
      d = @shape[i]
      return true unless d != 0
      return false unless @strides[i] == s
      s *= d
    end
    true
  end

  # :nodoc:
  def is_c_contiguous : Bool
    return true unless self.rank != 0
    if self.rank == 1
      return @shape[0] == 1 || @strides[0] == 1
    end

    s = 1
    (self.rank - 1).step(to: 0, by: -1) do |i|
      d = @shape[i]
      return true unless d != 0
      return false unless @strides[i] == s
      s *= d
    end
    true
  end

  private def update_flags(m : Num::ArrayFlags = Num::ArrayFlags::All)
    if m.fortran?
      if is_f_contiguous
        @flags |= Num::ArrayFlags::Fortran
        if self.rank > 1
          @flags &= ~Num::ArrayFlags::Contiguous
        end
      else
        @flags &= ~Num::ArrayFlags::Fortran
      end
    end
    if m.contiguous?
      if is_c_contiguous
        @flags |= Num::ArrayFlags::Contiguous

        if self.rank > 1
          @flags &= ~Num::ArrayFlags::Fortran
        end
      else
        @flags &= ~Num::ArrayFlags::Contiguous
      end
    end
  end
end
