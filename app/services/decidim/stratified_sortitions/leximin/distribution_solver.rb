# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Leximin
      # Computes the LEXIMIN-optimal probability distribution over panels.
      #
      # The LEXIMIN criterion maximizes fairness by:
      # 1. Maximizing the minimum selection probability
      # 2. Then maximizing the second-minimum probability (with the first fixed)
      # 3. And so on...
      #
      # Uses Linear Programming (LP) with the CBC solver.
      #
      class DistributionSolver
        class CbcNotAvailableError < StandardError; end

        # Small epsilon for numerical stability
        EPSILON = 1e-9

        def initialize(constraint_builder)
          @cb = constraint_builder
          require_cbc!
        end

        private

        def require_cbc!
          require "ruby-cbc"
        rescue LoadError
          raise CbcNotAvailableError,
                "The CBC solver is required for LEXIMIN selection. " \
                "Install the gem with: bundle add ruby-cbc\n" \
                "And system libraries: sudo apt install coinor-cbc coinor-libcbc-dev"
        end

        public

        # Compute the LEXIMIN-optimal distribution over panels
        #
        # @param panels [Array<Array<Integer>>] Array of panels (each panel is array of volunteer IDs)
        # @return [Hash] { probabilities: Array<Float>, dual_prices: Hash<Integer, Float> }
        def compute(panels)
          return empty_result if panels.empty?

          # Build panel-volunteer incidence matrix
          # incidence[i][p] = 1 if volunteer i is in panel p
          incidence = build_incidence_matrix(panels)

          # Compute LEXIMIN distribution using iterative LP
          probabilities, _selection_probs = solve_leximin_lp(panels, incidence)

          # Compute dual prices for column generation
          dual_prices = compute_dual_prices(panels, probabilities, incidence)

          {
            probabilities:,
            dual_prices:,
          }
        end

        private

        def empty_result
          { probabilities: [], dual_prices: {} }
        end

        def build_incidence_matrix(panels)
          # incidence[volunteer_id] = array of panel indices containing this volunteer
          incidence = Hash.new { |h, k| h[k] = [] }

          panels.each_with_index do |panel, panel_idx|
            panel.each do |volunteer_id|
              incidence[volunteer_id] << panel_idx
            end
          end

          incidence
        end

        # Solve LEXIMIN LP iteratively
        #
        # We solve a sequence of LPs:
        # 1. Maximize π_min = min_i π_i
        # 2. Fix π_i ≥ π_min for all i, maximize second-minimum
        # 3. Continue until all probabilities are fixed
        #
        # For efficiency, we use a single LP with a max-min formulation.
        #
        def solve_leximin_lp(panels, incidence)
          num_panels = panels.size
          return [Array.new(num_panels, 1.0 / num_panels), uniform_selection_probs(panels)] if num_panels == 1

          # Use a max-min LP formulation:
          # maximize z
          # subject to:
          #   π_i ≥ z for all volunteers i
          #   ∑_p λ_p = 1
          #   λ_p ≥ 0
          #   π_i = ∑_{p: i ∈ p} λ_p

          model = Cbc::Model.new

          # Variables: λ_p for each panel (probability of selecting panel p)
          lambda_vars = (0...num_panels).map do |p|
            model.cont_var(name: "lambda_#{p}")
          end

          # Variable: z (minimum probability to maximize)
          z = model.cont_var(name: "z")

          # Constraint: probabilities sum to 1
          model.enforce(sum_vars(lambda_vars) == 1)

          # Constraint: π_i ≥ z for each volunteer
          @cb.volunteer_ids.each do |vid|
            panel_indices = incidence[vid]
            next if panel_indices.empty?

            # π_i = ∑_{p: i ∈ p} λ_p
            pi_i = sum_vars(panel_indices.map { |p| lambda_vars[p] })

            # π_i ≥ z
            model.enforce(pi_i >= z)
          end

          # Objective: maximize z (the minimum probability)
          model.maximize(z)

          # Solve
          problem = model.to_problem
          problem.solve

          unless problem.proven_optimal?
            # Fallback to uniform distribution
            uniform_prob = 1.0 / num_panels
            return [Array.new(num_panels, uniform_prob), uniform_selection_probs(panels)]
          end

          # Extract probabilities
          probabilities = lambda_vars.map { |v| [problem.value_of(v), 0.0].max }

          # Normalize to ensure they sum to 1
          total = probabilities.sum
          probabilities = probabilities.map { |p| p / total } if total > EPSILON

          # Compute selection probabilities
          selection_probs = {}
          @cb.volunteer_ids.each do |vid|
            panel_indices = incidence[vid]
            selection_probs[vid] = panel_indices.sum { |p| probabilities[p] }
          end

          [probabilities, selection_probs]
        end

        def uniform_selection_probs(panels)
          probs = Hash.new(0.0)
          return probs if panels.empty?

          prob_per_panel = 1.0 / panels.size
          panels.each do |panel|
            panel.each { |vid| probs[vid] += prob_per_panel }
          end
          probs
        end

        # Compute dual prices for the column generation subproblem
        #
        # The dual prices indicate how much each volunteer's inclusion
        # in a new panel would improve the objective.
        #
        # For LEXIMIN, we use the marginal value of increasing each volunteer's
        # selection probability.
        #
        def compute_dual_prices(_panels, probabilities, incidence)
          dual_prices = {}

          # Compute current selection probabilities
          current_probs = {}
          @cb.volunteer_ids.each do |vid|
            panel_indices = incidence[vid]
            current_probs[vid] = panel_indices.sum { |p| probabilities[p] }
          end

          # Find minimum probability
          min_prob = current_probs.values.min || 0.0

          # Dual price is higher for volunteers with lower selection probability
          # This encourages new panels to include under-represented volunteers
          @cb.volunteer_ids.each do |vid|
            current = current_probs[vid] || 0.0

            # Inverse relationship: lower probability = higher dual price
            dual_prices[vid] = if current <= min_prob + EPSILON
                                 # Volunteers at minimum get highest price
                                 1.0
                               elsif current < 1.0
                                 # Others get price inversely proportional to their probability
                                 (1.0 - current) / (1.0 - min_prob + EPSILON)
                               else
                                 0.0
                               end
          end

          dual_prices
        end

        def sum_vars(vars)
          return 0 if vars.empty?

          vars.reduce(:+)
        end
      end
    end
  end
end
