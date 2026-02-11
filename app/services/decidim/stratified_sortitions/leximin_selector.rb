# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # LEXIMIN Selector Service
    #
    # Implements the LEXIMIN fair selection algorithm using column generation.
    # Based on "Fair algorithms for selecting citizens' assemblies" paper.
    #
    # The algorithm finds an optimal portfolio of panels (feasible selections)
    # and computes a probability distribution over them that maximizes fairness
    # in selection probabilities using the leximin criterion.
    #
    # @example
    #   result = LeximinSelector.new(stratified_sortition).call
    #   if result.success?
    #     result.panels        # Array of panels (each panel is array of participant IDs)
    #     result.probabilities # Probability for each panel
    #   else
    #     result.error         # Error message
    #   end
    #
    class LeximinSelector
      # Maximum number of column generation iterations
      MAX_ITERATIONS = 1000

      # Convergence threshold for reduced cost
      CONVERGENCE_THRESHOLD = 1e-6

      # Result object returned by the algorithm
      Result = Struct.new(:panels, :probabilities, :selection_probabilities, :iterations, :converged, :success, :error, keyword_init: true) do
        def success?
          success
        end
      end

      def initialize(stratified_sortition)
        @stratified_sortition = stratified_sortition
        @constraint_builder = Leximin::ConstraintBuilder.new(stratified_sortition)
      end

      # Execute the LEXIMIN algorithm
      #
      # @return [Result] containing panels, probabilities, and success status
      def call
        # Step 1: Check feasibility
        feasibility = Leximin::FeasibilityChecker.new(@constraint_builder).check
        unless feasibility[:feasible]
          return Result.new(
            panels: [],
            probabilities: [],
            selection_probabilities: {},
            success: false,
            error: feasibility[:errors].join("; ")
          )
        end

        # Step 2: Initialize with one feasible panel
        panel_generator = Leximin::PanelGenerator.new(@constraint_builder)
        initial_panel = panel_generator.find_feasible_panel
        return infeasible_result("No s'ha pogut trobar cap panel inicial vàlid") if initial_panel.nil?

        panels = [initial_panel]

        # Step 3: Column generation loop
        distribution_solver = Leximin::DistributionSolver.new(@constraint_builder)

        MAX_ITERATIONS.times do
          # Compute optimal distribution over current panels
          distribution = distribution_solver.compute(panels)

          # Try to find a new panel that improves the objective
          new_panel = panel_generator.find_improving_panel(distribution[:dual_prices])

          # Check convergence: no improving panel found
          break if new_panel.nil? || panels_include?(panels, new_panel)

          panels << new_panel
        end

        # Step 4: Compute final distribution
        final_distribution = distribution_solver.compute(panels)

        # Step 5: Compute selection probabilities for each volunteer
        selection_probs = compute_selection_probabilities(panels, final_distribution[:probabilities])

        Result.new(
          panels:,
          probabilities: final_distribution[:probabilities],
          selection_probabilities: selection_probs,
          success: true,
          error: nil
        )
      rescue StandardError => e
        Rails.logger.debug { "LEXIMIN Selector error: #{e.message}\n#{e.backtrace.join("\n")}" }
        Result.new(
          panels: [],
          probabilities: [],
          selection_probabilities: {},
          success: false,
          error: "LEXIMIN internal error: #{e.message}"
        )
      end

      private

      def infeasible_result(message)
        Result.new(
          panels: [],
          probabilities: [],
          selection_probabilities: {},
          success: false,
          error: message
        )
      end

      def panels_include?(panels, new_panel)
        new_panel_set = Set.new(new_panel)
        panels.any? { |p| Set.new(p) == new_panel_set }
      end

      def compute_selection_probabilities(panels, probabilities)
        selection_probs = Hash.new(0.0)

        panels.each_with_index do |panel, idx|
          prob = probabilities[idx] || 0.0
          panel.each do |volunteer_id|
            selection_probs[volunteer_id] += prob
          end
        end

        selection_probs
      end
    end
  end
end
