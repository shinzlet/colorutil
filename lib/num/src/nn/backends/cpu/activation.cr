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

module Num::NN
  extend self

  # Tanh squashes a real-valued number to the range [-1, 1]. It’s non-linear.
  # But unlike Sigmoid, its output is zero-centered. Therefore, in practice
  # the tanh non-linearity is always preferred to the sigmoid nonlinearity.
  #
  # ## Arguments
  #
  # * x : `Tensor` - `Tensor` to activate
  #
  # ## Examples
  #
  # ```
  # a = [0.1, 0.34, 0.65].to_tensor
  # Num::NN.tanh(a) # => [0.099668, 0.327477, 0.57167 ]
  # ```
  def tanh(x : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    Num.tanh(x)
  end

  # :ditto:
  def tanh!(x : Tensor(U, CPU(U))) forall U
    Num.tanh!(x)
  end

  # Derivative of the Tanh function
  #
  # ## Arguments
  #
  # * x : `Tensor` - `Tensor` to derive
  # * cached : `Tensor` - Cached `Tensor` from activation
  #
  # ## Examples
  #
  # ```
  # a = [0.1, 0.34, 0.65].to_tensor
  # Num::NN.d_tanh(a) # => [0.990066, 0.892759, 0.673193]
  # ```
  def tanh_prime(gradient : Tensor(U, CPU(U)), cached : Tensor(U, CPU(U))) forall U
    cached.map(gradient) do |x, y|
      y * (1 - x * x)
    end
  end

  # Sigmoid takes a real value as input and outputs another value
  # between 0 and 1. It’s easy to work with and has all the
  # nice properties of activation functions: it’s non-linear,
  # continuously differentiable, monotonic, and has a fixed
  # output range.
  #
  # ## Arguments
  #
  # * x : `Tensor` - `Tensor` to activate
  #
  # ## Examples
  #
  # ```
  # a = [0.1, 0.34, 0.65].to_tensor
  # puts Num::NN.sigmoid(a) # => [0.524979, 0.584191, 0.65701 ]
  # ```
  def sigmoid(x)
    x.map do |i|
      1 / (1 + Math.exp(-i))
    end
  end

  # :ditto:
  def sigmoid!(x : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    x.map! do |i|
      1 / (1 + Math.exp(-i))
    end
  end

  # Derivative of the Sigmoid function
  #
  # ## Arguments
  #
  # * gradient : `Tensor` - `Tensor` to derive
  # * cached : `Tensor` - Cached `Tensor` from activation
  #
  # ## Examples
  #
  # ```
  # a = [0.1, 0.34, 0.65].to_tensor
  # puts Num::NN.d_sigmoid(a) # => [0.249376, 0.242912, 0.225348]
  # ```
  def sigmoid_prime(gradient : Tensor(U, CPU(U)), cached : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    cached.map(gradient) do |x, y|
      x * (1 - x) * y
    end
  end

  # ReLU activation function
  #
  # ## Arguments
  #
  # * x : `Tensor` - Argument to activate
  def relu(x : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    Num.max(U.new(0), x)
  end

  # :ditto:
  def relu!(x : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    Num.max!(U.new(0), x)
  end

  # Derivative of the ReLU activation function
  #
  # ## Arguments
  #
  # * gradient : `Tensor` - `Tensor` to derive
  # * cached : `Tensor` Cached `Tensor` from activation
  def relu_prime(gradient : Tensor(U, CPU(U)), cached : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    cached.map(gradient) do |x, y|
      if x <= 0
        U.new(0)
      else
        y
      end
    end
  end

  # Leaky ReLU activation function
  #
  # ## Arguments
  #
  # * x : `Tensor` - Argument to activate
  def leaky_relu(x : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    x.map do |i|
      i > 0 ? i : U.new(i * 0.01)
    end
  end

  # :ditto:
  def leaky_relu!(x : Tensor(U, CPU(U))) forall U
    x.map! do |i|
      i > 0 ? i : i * 0.01
    end
  end

  # Leaky ReLU derivative
  #
  # ## Arguments
  #
  # * gradient : `Tensor` - `Tensor` to derive
  # * cached : `Tensor` - Cached `Tensor` from activation
  def leaky_relu_prime(gradient : Tensor(U, CPU(U)), cached : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    cached.map(gradient) do |x, y|
      if x <= 0
        y * 0.01
      else
        y
      end
    end
  end

  # Exponential linear unit activation
  #
  # ## Arguments
  #
  # * x : `Tensor` - `Tensor` to activate
  def elu(x : Tensor(U, CPU(U)), alpha = 0.01) : Tensor(U, CPU(U)) forall U
    x.map do |i|
      if i > 0
        i
      else
        U.new(alpha * (Math::E ** i - 1))
      end
    end
  end

  # :ditto:
  def elu!(x : Tensor(U, CPU(U)), alpha = 0.01) : Tensor(U, CPU(U)) forall U
    x.map! do |i|
      if i > 0
        i
      else
        alpha * (Math::E ** i - 1)
      end
    end
  end

  # ELU derivative
  #
  # ## Arguments
  #
  # * gradient : `Tensor` - `Tensor` to derive
  # * cached : `Tensor` - Cached `Tensor` from activation
  def elu_prime(gradient : Tensor(U, CPU(U)), cached : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    cached.map(gradient) do |x, y|
      if x <= 0
        Math.exp(y)
      else
        U.new(1)
      end
    end
  end

  # Sigmoid cross entropy loss
  #
  # ## Arguments
  #
  # * input : `Tensor` - Predicted values
  # * target : `Tensor` - Truth values
  def sigmoid_cross_entropy(input : Tensor(U, CPU(U)), target : Tensor(U, CPU(U))) forall U
    batch_size = input.shape[0]
    result = input.map(target) do |x, y|
      -y * x + Math.max(x, U.new(0)) + Math.log1p(Math.exp(-x.abs))
    end
    [result.sum / U.new(batch_size)].to_tensor
  end

  # Mean squared error loss
  #
  # ## Arguments
  #
  # * input : `Tensor` - Predicted values
  # * target : `Tensor` - Truth values
  def mse(input : Tensor(U, CPU(U)), target : Tensor(U, CPU(U))) : Tensor(U, CPU(U)) forall U
    result = input.map(target) do |i, j|
      (i - j) ** 2
    end
    [U.new(result.mean)].to_tensor
  end

  # :nodoc:
  def streaming_max_sumexp(t : Tensor(U, CPU(U))) forall U
    mx = U::MIN
    sumexp = U.new(0)

    t.each do |el|
      if el <= mx
        sumexp += Math.exp(el - mx)
      else
        sumexp = sumexp * Math.exp(mx - el) + 1
        mx = el
      end
    end
    {mx, sumexp}
  end

  # :nodoc:
  def logsumexp(t : Tensor(U, CPU(U))) forall U
    mx, sumexp = streaming_max_sumexp(t)
    mx + Math.log(sumexp, Math::E)
  end

  # :nodoc:
  def stable_softmax(x : U, mx : U, sumexp : U) forall U
    Math.exp(x - mx) / sumexp
  end

  # Computes softmax cross entropy loss
  #
  # ## Arguments
  #
  # * input : `Tensor` - Predicted values
  # * target : `Tensor` - Truth values
  def softmax_cross_entropy(input : Tensor(U, CPU(U)), target : Tensor(U, CPU(U))) forall U
    n = input.shape[0]
    result = (input * target).sum

    sum_logsumexp = U.new(0)

    input.each_axis(0) do |a|
      sum_logsumexp += logsumexp(a)
    end

    [U.new((sum_logsumexp - result) / n)].to_tensor
  end
end
