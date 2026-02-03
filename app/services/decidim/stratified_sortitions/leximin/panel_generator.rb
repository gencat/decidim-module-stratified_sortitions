# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Leximin
      # Generates feasible panels using Integer Linear Programming (ILP).
      #
      # Uses the COIN-OR CBC solver to find panels that satisfy:
      # - Exactly k volunteers selected (panel size)
      # - Quota constraints for each category (min/max)
      #
      # For column generation, it can also find panels that improve the
      # current LEXIMIN objective using dual prices.
      #
      class PanelGenerator
        class CbcNotAvailableError < StandardError; end

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

        # Find any feasible panel satisfying all constraints
        #
        # @return [Array<Integer>, nil] Array of volunteer IDs or nil if infeasible
        def find_feasible_panel
          solve_panel_ilp(nil)
        end

        # Find a panel that improves the LEXIMIN objective
        #
        # Uses dual prices from the master problem to find a panel with
        # positive reduced cost (improving the objective).
        #
        # @param dual_prices [Hash{Integer => Float}] dual prices for each volunteer
        # @return [Array<Integer>, nil] Array of volunteer IDs or nil if no improving panel
        def find_improving_panel(dual_prices)
          return find_feasible_panel if dual_prices.nil? || dual_prices.empty?

          solve_panel_ilp(dual_prices)
        end

        private

        # Solve the panel selection ILP
        #
        # Variables: x_i ∈ {0,1} for each volunteer i
        #
        # Constraints:
        #   ∑_i x_i = k (panel size)
        #   ℓ_j ≤ ∑_{i ∈ C_j} x_i ≤ u_j for each category j
        #
        # Objective:
        #   - If dual_prices nil: any feasible solution (maximize constant)
        #   - If dual_prices given: maximize ∑_i π_i * x_i (reduced cost)
        #
        # @param dual_prices [Hash, nil]
        # @return [Array<Integer>, nil]
        def solve_panel_ilp(dual_prices)
          return nil if @cb.num_volunteers.zero?

          model = Cbc::Model.new

          # Create binary variables for each volunteer
          x = @cb.volunteer_ids.map do |vid|
            model.bin_var(name: "x_#{vid}")
          end

          # Constraint: exactly k volunteers selected
          model.enforce(sum_vars(x) == @cb.panel_size)

          # Quota constraints for each category
          @cb.category_ids.each do |cat_id|
            quota = @cb.quotas[cat_id]
            volunteers_in_cat = @cb.category_volunteers[cat_id]

            next if volunteers_in_cat.empty?

            # Sum of x_i for volunteers in this category
            cat_vars = volunteers_in_cat.map do |vid|
              idx = @cb.volunteer_index(vid)
              x[idx]
            end.compact

            next if cat_vars.empty?

            cat_sum = sum_vars(cat_vars)

            # min <= sum <= max
            model.enforce(cat_sum >= quota[:min]) if quota[:min] > 0
            model.enforce(cat_sum <= quota[:max]) if quota[:max] < @cb.panel_size
          end

          # Objective function
          if dual_prices.nil? || dual_prices.empty?
            # Just find any feasible solution - maximize sum (constant effect)
            model.maximize(sum_vars(x))
          else
            # Maximize reduced cost: ∑_i π_i * x_i
            objective_terms = @cb.volunteer_ids.map.with_index do |vid, idx|
              price = dual_prices[vid] || 0.0
              x[idx] * price
            end
            model.maximize(sum_vars(objective_terms))
          end

          # Solve
          problem = model.to_problem
          problem.solve

          return nil unless problem.proven_optimal?

          # Check if reduced cost is positive (improving)
          if dual_prices.present?
            obj_value = problem.objective_value
            return nil if obj_value <= LeximinSelector::CONVERGENCE_THRESHOLD
          end

          # Extract selected volunteer IDs
          selected = []
          @cb.volunteer_ids.each_with_index do |vid, idx|
            selected << vid if problem.value_of(x[idx]) > 0.5
          end

          selected.empty? ? nil : selected
        end

        def sum_vars(vars)
          return 0 if vars.empty?

          vars.reduce(:+)
        end
      end
    end
  end
end
