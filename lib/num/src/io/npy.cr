# Copyright (c) 2021 Crystal Data Contributors
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

require "json"

class Tensor(T, S)
  private macro read_cast_return(dtype, file, size, shape)
    new_data = Bytes.new(sizeof({{ dtype }}) * {{ size }})
    {{ file }}.read_fully(new_data)
    ptr = new_data.to_unsafe.unsafe_as(Pointer({{ dtype }}))
    Tensor(T, S).new({{ shape }}, device: S) { |i| T.new(ptr[i]) }
  end

  # Reads a .npy file and returns a `Tensor` of the specified type.
  # If the ndarray is stored in a different type inside the file, it will be converted.
  #
  # ## Arguments
  #
  # * path : `String` - Filename of npy file to load
  #
  # NOTE: Only integer, unsigned integer and float ndarrays are supported at the moment.
  # NOTE: Only little endian files can be read due to laziness by the num.cr developer
  def self.from_npy(path : String) : Tensor(T, S)
    file = File.open(path, "r")
    file.read_fully(Bytes.new(8))

    header = Bytes.new(2)
    file.read_fully(header)
    size = IO::Memory.new(header).read_bytes(Int16, IO::ByteFormat::LittleEndian)

    header = file.read_string(size).downcase.tr("()'", "[]\"").gsub(/,]|],/, "]")
    json_header = JSON.parse(header)

    dtype = json_header["descr"].as_s
    shape = json_header["shape"].as_a.map &.as_i

    output_size = shape.product

    case dtype
    when "|u1"
      read_cast_return UInt8, file, output_size, shape
    when "<u2"
      read_cast_return UInt16, file, output_size, shape
    when "<u4"
      read_cast_return UInt32, file, output_size, shape
    when "|i1"
      read_cast_return Int8, file, output_size, shape
    when "<i2"
      read_cast_return Int16, file, output_size, shape
    when "<i4"
      read_cast_return Int32, file, output_size, shape
    when "<i8"
      read_cast_return Int64, file, output_size, shape
    when "<f4"
      read_cast_return Float32, file, output_size, shape
    when "<f8"
      read_cast_return Float64, file, output_size, shape
    else
      raise Num::Exceptions::ValueError.new(
        "Dtype #{dtype} is not currently supported by Num.cr"
      )
    end
  end

  # Export a Tensor to the Numpy format
  #
  # ## Arguments
  #
  # * path : `String` - filename of output `.npy` file.
  #
  # Only integer, unsigned integer and float ndarrays are supported at the moment.
  def to_npy(path : String)
    contig = self.dup(Num::RowMajor)
    data = contig.get_offset_ptr.unsafe_as(Pointer(UInt8)).to_slice(sizeof(T) * self.size)

    header = "\x93NUMPY"
    version = "\x01\x00"

    file = File.open(path, "w")
    file << header
    file << version

    type_hash = {
      UInt8   => "|u1",
      UInt16  => "<u2",
      UInt32  => "<u4",
      Int8    => "|i1",
      Int16   => "<i2",
      Int32   => "<i4",
      Int64   => "<i8",
      Float32 => "<f4",
      Float64 => "<f8",
    }

    dtype = type_hash[T]
    shape = "#{self.shape}"[1...-1]
    if self.rank == 1
      shape += ","
    end

    meta_data = "{'descr': '#{dtype}', 'fortran_order': False, 'shape': (#{shape}), }\n"
    header_size = UInt16.new(meta_data.bytesize)
    header_ptr = Pointer(UInt16).malloc(1) { |_| header_size }
    header_ptr = header_ptr.unsafe_as(Pointer(UInt8)).to_slice(2)

    file.write header_ptr
    file << meta_data
    file.write data
    file.close
  end
end
