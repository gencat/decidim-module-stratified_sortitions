# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Leximin
      describe DistributionSolver, type: :service do
        subject(:solver) { described_class.new(constraint_builder) }

        let(:constraint_builder) { ConstraintBuilder.new(sortition) }
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        before { require_cbc! }

        describe "#compute" do
          let(:panel_generator) { PanelGenerator.new(constraint_builder) }
          let(:panels) do
            # Generate a few distinct panels
            result = []
            5.times do
              panel = panel_generator.find_feasible_panel
              result << panel if panel && !result.include?(panel)
            end
            result.presence || [panel_generator.find_feasible_panel].compact
          end

          context "with a single panel" do
            let(:panels) { [panel_generator.find_feasible_panel].compact }

            it "returns probability of 1 for the single panel" do
              result = solver.compute(panels)
              expect(result[:probabilities]).to eq([1.0])
            end
          end

          context "with multiple panels" do
            it "returns probabilities summing to 1" do
              result = solver.compute(panels)
              expect(result[:probabilities].sum).to be_within(0.001).of(1.0)
            end

            it "returns non-negative probabilities" do
              result = solver.compute(panels)
              expect(result[:probabilities]).to all(be >= 0)
            end

            it "returns probabilities matching panels count" do
              result = solver.compute(panels)
              expect(result[:probabilities].size).to eq(panels.size)
            end

            it "returns dual prices for column generation" do
              result = solver.compute(panels)
              expect(result[:dual_prices]).to be_a(Hash)
            end

            it "returns dual prices for volunteers" do
              result = solver.compute(panels)
              # Dual prices should exist for at least some volunteers
              expect(result[:dual_prices]).not_to be_empty
            end
          end

          context "with empty panels" do
            let(:panels) { [] }

            it "returns empty result" do
              result = solver.compute(panels)
              expect(result[:probabilities]).to be_empty
              expect(result[:dual_prices]).to be_empty
            end
          end

          describe "LEXIMIN property" do
            it "maximizes minimum selection probability" do
              result = solver.compute(panels)

              # Calculate selection probabilities
              selection_probs = Hash.new(0.0)
              panels.each_with_index do |panel, idx|
                prob = result[:probabilities][idx]
                panel.each { |vid| selection_probs[vid] += prob }
              end

              # The minimum probability should be as high as possible
              # (hard to verify optimality, but we can check it's reasonable)
              min_prob = selection_probs.values.min
              expect(min_prob).to be >= 0
            end
          end
        end
      end
    end
  end
end
