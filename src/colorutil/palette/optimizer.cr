require "num"

require "../relation/relation.cr"
require "../color.cr"

# TODO: Remove
require "colorize"

include ColorUtil::Relations

module ColorUtil::Palette
  class Optimizer(T)
    # The maximum number of iterations that `optimize` runs.
    property iteration_target = 500

    # If more than this number of iterations occur without finding a new
    # best state, the `best` checkpoint will be restored.
    property exploration_period = 500

    # This is a scaling factor for creating a random candidate.
    # It is therefore the maximum value of `(generate_candidate - @lightness)[i]`
    # for any `i` and any possible candidate.
    # 0.25 works great for dark themes
    property neighbour_coefficient = 0.25f64

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

    getter plotdata = [] of Float64

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

    def initialize(@lookup : Hash(T, Color | UInt32), @relations, start = nil)
      variables = @lookup.reject { |k, v| v.is_a?(Color) }

      # Generate a random initial lightness vector
      @lightness = start || Tensor(Float64).random(0f64..1f64, [variables.size])
      @energy = compute_energy
      @best = create_checkpoint
    end

    # Performs the default optimization routine and returns the approximate
    # solution to the relations.
    def self.optimize(lookup : Hash(T, Color | UInt32), relations, start = nil)
      opt = Optimizer.new(lookup, relations, start)
      opt.optimize
      {opt.lightness, opt}
    end

    def optimize
      while @iteration < @iteration_target
        step_annealing
      end

      restore_checkpoint(@best)

      # puts "Annealing energy: #{@energy}".colorize :yellow
      # puts @lightness

      (0..100).each do
        step_gd(0.005)
        # break if energy < 2
      end

      # puts "Final energy: #{opt.energy}".colorize :yellow
      # puts opt.lightness
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

        if @iteration - @best.iteration > @exploration_period
          restore_checkpoint(best)

          # This will effectively just update `@best.iteration`
          @best = create_checkpoint
        end
      end
      plotdata << @energy
    end

    def step_gd(epsilon, step_size = nil)
      grad = gradient(epsilon)
      step_size ||= Math.sqrt((grad.transpose * grad).value) / 50000
      @lightness -= grad * step_size
      @lightness.map! { |value| Math.min(Math.max(value, 0f64), 1f64)}
      @energy = compute_energy
      # puts "gradient: #{grad}"
      # puts "step size: #{step_size}"
      # puts "new lightness: #{@lightness}"
      # puts
      # puts "new energy #{@energy}"
      plotdata << @energy
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
      completion = @iteration.to_f64 / @iteration_target
      #@temperature = 1 - completion # Math.exp(-3 * completion)
      #@temperature = A * ( D - Math.tanh(STEEPNESS * (completion - 1/2)) )

      # Current best
      #@temperature = (Math.exp(-completion) - Math.exp(-1)) / (1 - Math.exp(-1))
      @temperature = {1f64 - 8 * completion, (1 - completion) / 4}.max
    end

    # Generates a 
    def generate_candidate : Tensor(Float64)
      span = @neighbour_coefficient * @temperature
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
