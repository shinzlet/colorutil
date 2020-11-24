require "num"

require "../relation.cr"
require "../color.cr"

module ColorUtil::Palette
  class Optimizer(T)
    # TODO: experiment with these
    DEFAULT_ITERATIONS = 500

    property iteration : UInt32 = 0
    property max_iterations = DEFAULT_ITERATIONS

    property relations : Array(Relation)

    # Contains both color constants and [h, s] arrays. After optimization,
    # the resulting palette will be exactly this hash, except the `[h, s]`
    # arrays will be completed with `[h, s, l]` arrays that best satisfy
    # the relations being optimized for.
    property basis : Hash(T, Color | Array(Float64))

    # Connects each key in `basis` with either:
    # - The index in `lightness` where that color is being solved for
    # - Or the constant `Color` that was passed in with that key
    #
    # This is used to resolve the working location of constants and variables.
    property lookup : Hash(T, Color | UInt32)

    # `lightness[lookup[key]]` is the current estimate of the lightness that
    # belongs with the hue and saturation specified in `basis[key]`.
    property lightness : Tensor(Float64)

    def initialize(@hash, @relations)
      # TODO: Test all of this, work on step_annealing and candidate generation
      keys = @hash.keys

      # Decompose `hash` into a more useful representation
      lookup = hash.new(initial_capacity = keys.size)
      variable_count = 0

      keys.each do |key|
        value = hash[key]

        if value.is_a? Color
          @lookup[key] = value
        else
          @lookup[key] = variable_count
          variable_count += 1
        end
      end

      # Generate a random initial lightness vector
      @lightness = Tensor(Float64).random(variable_count)
    end

    def self.optimize(hash, rules) : Hash(T, Color)
      opt = Optimizer.new(hash, relations)

      while opt.iteration < opt.max_iterations
        opt.step_annealing
      end

      to_h
    end

    def step_annealing()
      @iteration += 1
      update_temperature
      candidate = generate_candidate
      candidate_energy = energy(candidate)

    end

    # Ensures that the temperature of the system reflects the number of annealing
    # steps that have been taken.
    #
    # Returns the annealing temperature.
    def update_temperature() : Float64
      completion = @iteration.to_f64 / @max_iteration
      @temperature = 1 - Math.exp(completion - 1f64)
    end

    # Generates a 
    def generate_candidate() : Tensor(Float64)
    end

    def to_h()
    end
  end
end
