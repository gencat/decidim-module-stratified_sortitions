# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Leximin
      # Samples a single panel from the LEXIMIN distribution.
      #
      # Given a set of panels and their probabilities (from LeximinSelector),
      # this service selects one panel according to the probability distribution.
      #
      # The sampling is cryptographically secure using SecureRandom.
      #
      # @example
      #   leximin_result = LeximinSelector.new(stratified_sortition).call
      #   sampler = PanelSampler.new(leximin_result.panels, leximin_result.probabilities)
      #   selected_panel = sampler.sample
      #   # => [participant_id_1, participant_id_2, ...]
      #
      class PanelSampler
        # Result object for sampling operation
        Result = Struct.new(:selected_panel, :selected_index, :random_value, :success, :error, keyword_init: true) do
          def success?
            success
          end
        end

        def initialize(panels, probabilities, random_seed: nil)
          @panels = panels
          @probabilities = normalize_probabilities(probabilities)
          @random_seed = random_seed
        end

        # Sample a panel according to the probability distribution
        #
        # @return [Result] containing the selected panel and metadata
        def sample
          return error_result("No hi ha panels disponibles per mostrejar") if @panels.empty?
          return error_result("Les probabilitats no coincideixen amb el nombre de panels") if @panels.size != @probabilities.size

          # Generate random value in [0, 1)
          random_value = generate_random_value

          # Select panel using cumulative distribution
          selected_index = select_panel_index(random_value)

          Result.new(
            selected_panel: @panels[selected_index],
            selected_index:,
            random_value:,
            success: true,
            error: nil
          )
        rescue StandardError => e
          error_result("Error en el mostreig: #{e.message}")
        end

        # Sample multiple panels (with replacement)
        #
        # @param count [Integer] number of panels to sample
        # @return [Array<Result>] array of sampling results
        def sample_multiple(count)
          Array.new(count) { sample }
        end

        # Get the cumulative distribution function
        #
        # @return [Array<Float>] cumulative probabilities
        def cumulative_distribution
          cumsum = 0.0
          @probabilities.map { |p| cumsum += p }
        end

        private

        def normalize_probabilities(probs)
          return [] if probs.blank?

          total = probs.sum.to_f
          return probs if (total - 1.0).abs < 1e-9

          # Normalize to sum to 1
          if total.positive?
            probs.map { |p| p / total }
          else
            # Uniform distribution if all zeros
            uniform = 1.0 / probs.size
            Array.new(probs.size, uniform)
          end
        end

        def generate_random_value
          if @random_seed
            # Deterministic for testing
            Random.new(@random_seed).rand
          else
            # Cryptographically secure random
            SecureRandom.random_number
          end
        end

        def select_panel_index(random_value)
          cumsum = 0.0

          @probabilities.each_with_index do |prob, idx|
            cumsum += prob
            return idx if random_value < cumsum
          end

          # Edge case: return last panel (handles floating point errors)
          @panels.size - 1
        end

        def error_result(message)
          Result.new(
            selected_panel: [],
            selected_index: nil,
            random_value: nil,
            success: false,
            error: message
          )
        end
      end
    end
  end
end
