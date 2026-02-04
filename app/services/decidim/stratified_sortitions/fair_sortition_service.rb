# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # Complete Fair Sortition Service
    #
    # Orchestrates the full LEXIMIN-based fair sortition process:
    # 1. Runs LEXIMIN algorithm to find optimal panel distribution
    # 2. Samples a panel according to the fair probability distribution
    # 3. Returns the selected participants
    #
    # Supports two modes:
    # - Single-phase: Generate and sample in one call
    # - Two-phase: Generate portfolio first, sample later (for public ceremonies)
    #
    # @example Basic usage (single-phase)
    #   result = FairSortitionService.new(stratified_sortition).call
    #   if result.success?
    #     result.selected_participants  # Array of SampleParticipant records
    #     result.selection_log          # Audit information
    #   end
    #
    # @example Two-phase usage (for public/auditable draws)
    #   service = FairSortitionService.new(stratified_sortition)
    #
    #   # Phase 1: Generate portfolio (can be done in background)
    #   portfolio_result = service.generate_portfolio
    #   # Publish portfolio_result.portfolio.panels for transparency
    #
    #   # Phase 2: Sample from portfolio (can be done publicly)
    #   final_result = service.sample_from_portfolio(verification_seed: SecureRandom.hex(64))
    #
    # @example With verification seed (for auditable draws)
    #   result = FairSortitionService.new(stratified_sortition, verification_seed: "public_seed_123").call
    #
    class FairSortitionService
      # Result object containing all sortition outputs
      Result = Struct.new(
        :selected_participants,
        :selected_participant_ids,
        :selection_probabilities,
        :portfolio,
        :sampling_result,
        :selection_log,
        :success,
        :error,
        keyword_init: true
      ) do
        def success?
          success
        end
      end

      # Result for portfolio generation
      PortfolioResult = Struct.new(:portfolio, :success, :error, keyword_init: true) do
        def success?
          success
        end
      end

      def initialize(stratified_sortition, verification_seed: nil)
        @stratified_sortition = stratified_sortition
        @verification_seed = verification_seed
      end

      # Execute the complete fair sortition process (single-phase)
      #
      # This generates the portfolio and samples in one call.
      # For two-phase process, use generate_portfolio and sample_from_portfolio.
      #
      # @return [Result] containing selected participants and audit log
      def call
        # Check if already sampled
        return error_result(error: "El sorteig ja s'ha realitzat per aquest procés") if existing_portfolio&.sampled?

        # Generate or retrieve portfolio
        portfolio = find_or_generate_portfolio
        return error_result(error: portfolio.error) unless portfolio.is_a?(PanelPortfolio)

        # Sample from portfolio
        sample_from_portfolio(verification_seed: @verification_seed)
      end

      # Generate portfolio without sampling (Phase 1 of two-phase process)
      #
      # Creates a PanelPortfolio with all candidate panels and their probabilities.
      # The portfolio is persisted to the database for later sampling.
      #
      # @return [PortfolioResult] containing the generated portfolio
      def generate_portfolio
        if existing_portfolio.present?
          return PortfolioResult.new(
            portfolio: existing_portfolio,
            success: true,
            error: nil
          )
        end

        start_time = Time.current
        leximin_result = LeximinSelector.new(@stratified_sortition).call

        unless leximin_result.success?
          return PortfolioResult.new(
            portfolio: nil,
            success: false,
            error: leximin_result.error
          )
        end

        @existing_portfolio = portfolio = PanelPortfolio.create!(
          stratified_sortition: @stratified_sortition,
          panels: leximin_result.panels,
          probabilities: leximin_result.probabilities,
          selection_probabilities: leximin_result.selection_probabilities,
          generated_at: Time.current,
          generation_time_seconds: Time.current - start_time,
          num_iterations: leximin_result.panels.size, # Approximation
          convergence_achieved: true
        )

        PortfolioResult.new(
          portfolio:,
          success: true,
          error: nil
        )
      rescue StandardError => e
        PortfolioResult.new(
          portfolio: nil,
          success: false,
          error: "Error generant la cartera de panels: #{e.message}"
        )
      end

      # Sample from existing portfolio (Phase 2 of two-phase process)
      #
      # @param verification_seed [String, nil] Optional seed for reproducible sampling
      # @return [Result] containing selected participants and audit log
      def sample_from_portfolio(verification_seed: nil)
        portfolio = existing_portfolio

        return error_result(error: "There is no panel portfolio. Execute `generate_portfolio` first") unless portfolio

        if portfolio.sampled?
          # Return existing result
          return build_success_result(portfolio)
        end

        sampling_result = portfolio.sample!(verification_seed:)

        return error_result(error: sampling_result.error) unless sampling_result.success?

        build_success_result(portfolio.reload)
      rescue StandardError => e
        Rails.logger.error("Error while sampling portfolio: #{e.message}\n#{e.backtrace.join("\n")}")
        error_result(error: "Error while sampling: #{e.message}")
      end

      # Verify a previous sortition result
      #
      # Given the same seed and data, should produce the same result
      #
      # @param expected_ids [Array<Integer>] expected selected participant IDs
      # @param verification_seed [String] the seed used in the original draw
      # @return [Boolean] true if verification passes
      def verify(expected_ids, verification_seed:)
        portfolio = existing_portfolio
        return false unless portfolio&.sampled?

        # Re-sample with the same seed (doesn't persist)
        random_seed = Decidim::StratifiedSortitions.derive_random_seed(verification_seed)
        sampler = Leximin::PanelSampler.new(
          portfolio.panels,
          portfolio.probabilities,
          random_seed:
        )
        result = sampler.sample
        return false unless result.success?

        Set.new(result.selected_panel) == Set.new(expected_ids)
      end

      # Check if this sortition has already been performed
      #
      # @return [Boolean]
      def already_performed?
        existing_portfolio&.sampled? || false
      end

      # Get the existing portfolio if any
      #
      # @return [PanelPortfolio, nil]
      def existing_portfolio
        @existing_portfolio ||= @stratified_sortition.panel_portfolio
      end

      private

      def find_or_generate_portfolio
        return existing_portfolio if existing_portfolio.present?

        result = generate_portfolio
        result.success? ? result.portfolio : result
      end

      def load_participants(participant_ids)
        return [] if participant_ids.empty?

        SampleParticipant
          .where(id: participant_ids)
          .order(:id)
          .to_a
      end

      def build_success_result(portfolio)
        Result.new(
          selected_participants: portfolio.selected_participants,
          selected_participant_ids: portfolio.selected_panel,
          selection_probabilities: portfolio.selection_probabilities,
          portfolio:,
          sampling_result: Leximin::PanelSampler::Result.new(
            selected_panel: portfolio.selected_panel,
            selected_index: portfolio.selected_panel_index,
            random_value: portfolio.random_value_used,
            success: true,
            error: nil
          ),
          selection_log: portfolio.audit_log,
          success: true,
          error: nil
        )
      end

      def error_result(error:)
        Result.new(
          selected_participants: [],
          selected_participant_ids: [],
          selection_probabilities: {},
          portfolio: existing_portfolio,
          sampling_result: nil,
          selection_log: { error: },
          success: false,
          error:
        )
      end
    end
  end
end
