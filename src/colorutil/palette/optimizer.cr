require "num"

require "../relation/relation.cr"
require "../color.cr"

# TODO: Remove
require "colorize"

include ColorUtil::Relations

module ColorUtil::Palette
  class Optimizer(T)
    # The maximum number of iterations that `optimize` runs.
    MAX_ITERATIONS = 500

    # If more than this number of iterations occur without finding a new
    # best state, the `best` checkpoint will be restored.
    EXPLORATION_PERIOD = 100

    # This is a scaling factor for creating a random candidate.
    # It is therefore the maximum value of `(generate_candidate - @lightness)[i]`
    # for any `i` and any possible candidate.
    NEIGHBOUR_COEFFICIENT = 2f64

    alias PartialColor = Array(Float64)
    alias AnyColor = PartialColor | ColorUtil::Color

    record Checkpoint,
      lightness : Tensor(Float64),
      energy : Float64,
      iteration : UInt32

    property iteration : UInt32 = 0

    # The annealing temperature at the current timestep. Starts at 1, and decreases as
    # `iteration` increases.
    getter temperature = 1f64

    property relations : Array(Relation)

    # Connects each key in `basis` with either:
    # - The index in `lightness` where that color is being solved for
    # - Or the constant `Color` that was passed in with that key
    #
    # This is used to resolve the working location of constants and variables.
    property lookup : Hash(T, Color | UInt32)

    # TODO: I can probalby remove `lightness` in its entirety if the user
    # passes in the number of variables to optimize.
    # `lightness[lookup[key]]` is the current estimate of the lightness associated
    # with `key`.
    property lightness : Tensor(Float64)

    # The output of the energy function when applied to `lightness`.
    # The energy functon can be (relatively) expensive, so this variable
    # is used to avoid needless recomputation in the optimizer loop.
    property energy : Float64

    # A snapshot of the best condition the optimizer has ever reached.
    property best : Checkpoint

    def initialize(@lookup : Hash(T, Color | UInt32), @relations)
      variables = @lookup.reject { |k, v| v.is_a?(Color) }

      # Generate a random initial lightness vector
      @lightness = Tensor(Float64).random(0f64..1f64, [variables.size])
      @energy = compute_energy
      @best = create_checkpoint
    end

    # Performs the default optimization routine and returns the approximate
    # solution to the relations.
    def self.optimize(lookup : Hash(T, Color | UInt32), relations) : Tensor(Float64)
      opt = Optimizer.new(lookup, relations)

      while opt.iteration < MAX_ITERATIONS
        opt.step_annealing
      end

      opt.restore_checkpoint(opt.best)

      puts "Annealing energy: #{opt.energy}".colorize :yellow
      puts opt.lightness

      (0..100).each do
        opt.step_gd(0.00005, 0.001)
      end

      puts "Final energy: #{opt.energy}".colorize :yellow
      puts opt.lightness
      opt.lightness
    end

    def step_annealing()
      @iteration += 1

      update_temperature

      candidate = generate_candidate
      candidate_energy = compute_energy(candidate)
      energy_drop = @energy - candidate_energy

      prob = acceptance_probability(energy_drop)

      if prob > Random.rand
        @lightness = candidate
        @energy = candidate_energy
        # puts
        # puts "Beginning iteration #{@iteration}".colorize :blue
        # puts "\tStarting at: #{@lightness}"
        # puts "\tEnergy: #{@energy}"
        # puts "\tEnergy drop: #{energy_drop}"
        # puts "\tProbability: #{prob}".colorize prob > 0.5 ? :green : :red
      end

      # Create a checkpoint if this is the lowest energy we've had
      if @energy < @best.energy
        @best = create_checkpoint
      else
        # In this branch, we're currently exploring the energy surface. This is
        # core to simulated annealing, but we don't want it to get out of hand.
        # So, if it's been too long, we restore our progress to the best we've ever
        # found.

        if @iteration - @best.iteration > EXPLORATION_PERIOD
          restore_checkpoint(best)

          # This will effectively just update `@best.iteration`
          @best = create_checkpoint
        end
      end
    end

    def step_gd(epsilon, step_size = nil)
      grad = gradient(epsilon)
      step_size ||= Math.sqrt((grad.transpose * grad).value) / 10000
      @lightness -= grad * step_size
      @lightness.map! { |value| Math.min(Math.max(value, 0f64), 1f64)}
      @energy = compute_energy
      # puts "gradient: #{grad}"
      # puts "step size: #{step_size}"
      # puts "new lightness: #{@lightness}"
      # puts
    end

    def gradient(epsilon)
      grad = Tensor(Float64).zeros_like(@lightness)
      
      @lightness.size.times do |idx|
        copy = @lightness.dup
        copy[idx] += epsilon
        grad[idx] = (compute_error(copy) - compute_error(@lightness)) / epsilon
        # puts "\tcopy: #{copy}"
        # puts "\tcopy error: #{compute_error(copy)}"
        # puts "\tnormal: #{@lightness}"
        # puts "\tnormal error: #{compute_error(@lightness)}"
      end

      grad
    end

    # Ensures that the temperature of the system reflects the number of annealing
    # steps that have been taken.
    #
    # Returns the annealing temperature.
    STEEPNESS = 1f64
    D = Math.tanh(STEEPNESS / 2)
    A = 1/(2 * D)
    def update_temperature() : Float64
      completion = @iteration.to_f64 / MAX_ITERATIONS
      #@temperature = 1 - completion # Math.exp(-3 * completion)
      #@temperature = A * ( D - Math.tanh(STEEPNESS * (completion - 1/2)) )
      @temperature = (Math.exp(-completion) - Math.exp(-1)) / (1 - Math.exp(-1))
    end

    # Generates a 
    def generate_candidate : Tensor(Float64)
      span = NEIGHBOUR_COEFFICIENT * @temperature
      ret = @lightness + Tensor(Float64).random(-span..span, @lightness.shape)
      ret.map! { |value| Math.min(Math.max(value, 0f64), 1f64)}
      ret
    end

    # Returns a checkpoint that saves the current state of the optimizer.
    def create_checkpoint : Checkpoint
      Checkpoint.new(
        @lightness,
        @energy,
        @iteration
      )
    end

    def restore_checkpoint(checkpoint = @best)
      @lightness = checkpoint.lightness
      @energy = checkpoint.energy
    end

    # Returns the probability of accepting a new state given the annealing temperatue
    # and the energy of the new state.
    # Requires normalized energies on [0, 1]
    def acceptance_probability(energy_drop) : Float64
      return 1f64 if energy_drop > 0
      # TODO: 100 should not be a constant!
      return @temperature * (1 + Math.tanh(energy_drop / 100))
    end

    # Copmutes the energy function, which is a function of the error.
    def compute_energy(lightness = @lightness) : Float64
      Math.sqrt(compute_error(lightness))
    end

    # Computes the sum error from each relation given a lightness.
    def compute_error(lightness = @lightness) : Float64
      (@relations.map &.error(lightness)).sum
    end
  end
end
