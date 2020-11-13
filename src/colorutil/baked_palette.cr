require "num"
require "./color"
require "colorize"

module ColorUtil
  struct BakedPalette
    ITERATIONS = 500
    NEIGHBOUR_COEFFICIENT = 1f64
    EXPLORATION_TOLERANCE = 50

    @palette : Array(Color)

    # TODO: Implement error caching in constructor
    # getter error : Float64

    def initialize(source : SemanticPalette)
      max_error = BakedPalette.max_error(source.rules)

      lightness = Tensor(Float64).random(0f64..1f64, [source.qualia.size + 1])
      lightness[0] = source.driver.approx_relative_luminance
      energy = BakedPalette.energy(lightness, source.rules, max_error)

      best_lightness = lightness
      lowest_energy = energy
      highscore_iteration = 0

      # Runs simulated annealing - a metaheuristic to approximate the global minimum energy
      ITERATIONS.times do |i|
        completion = i.to_f64 / ITERATIONS
        temp = BakedPalette.temperature(completion)
        candidate = BakedPalette.neighbour(lightness, temp)
        candidate[0] = lightness[0] # copy over the driver's relative luminance
        candidate_energy = BakedPalette.energy(candidate, source.rules, max_error)
        acceptance_prob = BakedPalette.acceptance_probability(energy, candidate_energy, temp)

        if energy < lowest_energy
          lowest_energy = energy
          best_lightness = lightness
          highscore_iteration = i
        end

        if i - highscore_iteration > EXPLORATION_TOLERANCE
          lightness = best_lightness
          energy = lowest_energy
          highscore_iteration = i
        end

        # puts "iteration #{i}"
        # puts "temperature: #{temp}"
        # puts "current error: #{BakedPalette.error(lightness, source.rules)}".colorize(:red)
        # puts "lightness: #{lightness}"
        # puts "candidate: #{candidate}"
        # puts "current energy: #{energy}"
        # puts "candidate energy: #{candidate_energy}"
        # puts "acceptance probability: #{acceptance_prob}"
        # puts "lightness: #{lightness}"
        # puts "temperature: #{temp}"

        if Random.rand < acceptance_prob
          # puts "(candidate found) dE = #{candidate_energy - energy}".colorize(:green)
          lightness = candidate
          energy = candidate_energy
        end
      end


      # Copy lightness information into a color palette
      @palette = [source.driver]

      puts lightness
      source.qualia.each_with_index do |hs, idx|
        @palette << Color.from_hsl(hs[0], hs[1],
                                   inverse_approx_relative_luminance(best_lightness[idx + 1].value))
      end
    end

    # Returns the probability of accepting a new state given the annealing temperatue
    # and the energy of the new state.
    # Requires normalized energies on [0, 1]
    def self.acceptance_probability(energy, new_energy, temp)
      # Semantically speaking, this is a measure of how much the error has gone down
      decrease = energy - new_energy

      return 1 if decrease > 0
      return temp * (1 + Math.tanh(decrease))

      # This function is sigmoidal when the temperature is zero, and a constant 100%
      # when the temperature is 1. That is to say, for larger values of decrase,
      # the probability will increase, but that increase is greater at low temperatures.
      # When the 'material is cold', this becomes greedy search.
      # return 1/2 * (1 + Math.tanh(decrease)) * (1 - temp/2) + temp/2
    end

    # Returns the energy for a state. This is quite wishy-washy - for a random set of lightnesses,
    # I found that almost all of them had miniscule energy compared to the maximum error possible.
    # So, i played with tanh to try to normalize the outputs into a more uniform range. The
    # coefficient 51 gave me a mean energy of 0.5, so that's what i stuck with.
    def self.energy(state, rules, max_error)
        Math.tanh(51 * error(state, rules) / max_error)
        # Math.min(error(state, rules) / 30, 1)
        # error(state, rules)
    end

    # Returns an upper bound on how large the error in a system could be given a 
    # set of rules.
    # This upper bound is not exact - it assumes that the contrast error is always
    # the largest that it could be, which for some rule sets, may be contradictory.
    # For example, if there are two rules between two colors, dictating that they
    # contraast fully and not at all, this method will return an unattainable error
    # level.
    def self.max_error(rules)
      acc = 0

      rules.each do |rule|
        acc += ([21 - rule[2], rule[2]].max) ** 2
      end

      acc
    end

    # Returns a modified version of the state according to the annealing temperature.
    def self.neighbour(state, temp)
      span = NEIGHBOUR_COEFFICIENT * temp
      ret = state + Tensor(Float64).random(-span..span, state.shape)
      ret.map! { |value| Math.min(Math.max(value, 0f64), 1f64)}
      ret
    end

    # Returns the annealing temperature at a certain completion step in the domain [0, 1].
    # This function, too, returns a number in the range [0, 1].
    def self.temperature(completion)
      1f64 - completion
      1 - Math.exp(completion - 1f64)
    end

    # Returns a tensor of the same size as the input storing the analytic solution for the
    # error gradient in each variable.
    def self.error_gradient(lightness : Tensor(Float64), rules : Array(Array(Float64))) : Tensor(Float64)
      grad = Tensor(Float64).zeros(lightness.shape)

      rules.each do |rule|
        # Compute the partial derivative of the error in each term of the contrast
        # rule.

        2.times do |wrt_idx|
          fixed_idx = wrt_idx ^ 1

          wrt = rule[wrt_idx].to_i32
          fixed = rule[fixed_idx].to_i32

          grad[wrt] += 2 \
            * ( ColorUtil.wcag_contrast(lightness[fixed].value, lightness[wrt].value) - rule[2] ) \
            * d_contrast(lightness[fixed].value, lightness[wrt].value)
        end
      end

      return grad
    end

    def self.error(lightness : Tensor(Float64), rules : Array(Array(Float))) : Float64
      acc = 0f64

      rules.each do |rule|
        acc += (wcag_contrast(lightness[rule[0].to_i32].value, lightness[rule[1].to_i32].value) - rule[2]) ** 2
      end

      return acc
    end

    # Returns the partial derivative of the WCAG contrast function in the variable
    # `wrt` (with respect to) when the other lightness is `fixed`.
    def self.d_contrast(fixed, wrt) : Float64
      if wrt == fixed
        # This might be undesirable, if the system is getting stuck at the inflection point.
        # Consider changing to be a small random number (+/-0.05)
        return 0.05f64
      elsif wrt < fixed
        return -(fixed + 0.05f64) / (wrt + 0.05f64) ** 2
      else
        return 1 / (fixed + 0.05f64)
      end
    end
  end
end
