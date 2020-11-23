require "../relation.cr"
require "../color.cr"

module ColorUtil::Palette
  class Optimizer(T)
    # TODO: experiment with these
    DEFAULT_ITERATIONS = 500

    property iteration : UInt32 = 0
    property relations : Array(Relation)
    property max_iterations = DEFAULT_ITERATIONS

    # 
    property hash : Hash(T, Color | Array(Float64))
    # An array of all the keys in `hash` that have pre-determined lightness
    property constants : Array(T)
    # variables[i] is the key that lightness[i] should be mapped to, once computed
    property variables : Array(T)

    property lightness : Tensor(Float64)

    def initialize(@hash, @relations)
      keys = @hash.keys

      # Decompose `hash` into a more useful representation
      constants = Array(T).new(keys.size)
      variables = Array(T).new(keys.size)

      keys.each do |key|
        if hash[key].is_a? Color
          constants << key
        else
          variables << key
        end
      end

      # Generate a random initial lightness vector
      lightness = Tensor(Float64).random(keys.size)
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
      completion = (Float64) @iteration / @max_iteration
      @temperature = 1 - Math.exp(completion - 1f64)
    end

    # Generates a 
    def generate_candidate() : Tensor(Float64)
    end

    def to_h()
    end
  end
end
