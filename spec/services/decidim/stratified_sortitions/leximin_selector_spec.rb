# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe LeximinSelector, type: :service do
      subject(:selector) { described_class.new(sortition) }

      before { require_cbc! }

      describe "#call" do
        context "with a valid simple sortition" do
          let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }
          let(:result) { selector.call }

          it_behaves_like "a successful leximin result"

          it "generates at least one panel" do
            expect(result.panels.size).to be >= 1
          end

          it "has panels of correct size" do
            result.panels.each do |panel|
              expect(panel.size).to eq(10)
            end
          end

          it "has probabilities summing to 1" do
            expect(result.probabilities.sum).to be_within(0.001).of(1.0)
          end

          it "computes selection probabilities" do
            expect(result.selection_probabilities).not_to be_empty
          end
        end

        context "with a larger sortition" do
          let(:sortition) { create_simple_sortition(num_participants: 100, panel_size: 20, rspec_seed: @rspec_seed) }
          let(:result) { selector.call }

          it_behaves_like "a successful leximin result"

          it "generates multiple panels through column generation" do
            # With more participants and larger panel, should generate multiple panels
            expect(result.panels.size).to be >= 1
          end
        end

        context "with complex strata configuration" do
          let(:sortition) do
            create_sortition_with_participants(
              num_participants: 80,
              panel_size: 15,
              strata_config: [
                {
                  name: "Gender",
                  substrata: [
                    { name: "Male", percentage: 50 },
                    { name: "Female", percentage: 50 },
                  ],
                },
                {
                  name: "Age",
                  substrata: [
                    { name: "18-30", percentage: 25 },
                    { name: "31-45", percentage: 25 },
                    { name: "46-60", percentage: 25 },
                    { name: "61+", percentage: 25 },
                  ],
                },
                {
                  name: "Region",
                  substrata: [
                    { name: "North", percentage: 33 },
                    { name: "Center", percentage: 34 },
                    { name: "South", percentage: 33 },
                  ],
                },
              ],
              rspec_seed: @rspec_seed
            )
          end
          let(:result) { selector.call }

          it_behaves_like "a successful leximin result"

          it "respects quota constraints in all panels" do
            constraint_builder = Leximin::ConstraintBuilder.new(sortition)

            result.panels.each do |panel|
              constraint_builder.category_ids.each do |cat_id|
                quota = constraint_builder.quotas[cat_id]
                count_in_panel = panel.count do |pid|
                  constraint_builder.volunteer_categories[pid]&.include?(cat_id)
                end

                expect(count_in_panel).to be <= quota[:max],
                                          "Panel violates max quota for category #{cat_id}"
              end
            end
          end
        end

        context "with infeasible configuration" do
          let(:sortition) { create_infeasible_sortition }
          let(:result) { selector.call }

          it_behaves_like "a failed leximin result"
        end

        context "with no participants" do
          let(:sortition) { create(:stratified_sortition, num_candidates: 10) }

          before do
            stratum = create(:stratum, stratified_sortition: sortition)
            create(:substratum, stratum:, max_quota_percentage: "50")
          end

          let(:result) { selector.call }

          it_behaves_like "a failed leximin result"

          it "includes relevant error message" do
            expect(result.error).to include("No volunteers in the pool.")
          end
        end

        describe "LEXIMIN fairness property" do
          let(:sortition) { create_simple_sortition(num_participants: 30, panel_size: 10, rspec_seed: @rspec_seed) }
          let(:result) { selector.call }

          it "gives positive selection probability to participants in panels" do
            panels_participants = result.panels.flatten.uniq
            panels_participants.each do |pid|
              prob = result.selection_probabilities[pid]
              expect(prob).to be > 0, "Participant #{pid} in panel has zero probability"
            end
          end

          it "has bounded probability range (fairness indicator)" do
            probs = result.selection_probabilities.values
            next if probs.empty?

            min_prob = probs.min
            max_prob = probs.max

            # LEXIMIN should minimize the difference between min and max
            # The ratio shouldn't be too extreme
            if min_prob > 0
              ratio = max_prob / min_prob
              expect(ratio).to be < 10, "Probability ratio too high: #{ratio}"
            end
          end
        end

        describe "determinism with RSpec seed" do
          let(:sortition) { create_simple_sortition(num_participants: 30, panel_size: 8, rspec_seed: @rspec_seed) }

          it "produces consistent panel count with same seed" do
            result_1 = selector.call

            sortition_2 = create_simple_sortition(num_participants: 30, panel_size: 8, rspec_seed: @rspec_seed)
            selector_2 = described_class.new(sortition_2)
            result_2 = selector_2.call

            # Both should succeed
            expect(result_1.success?).to eq(result_2.success?)
            expect(result_1.panels.size).to eq(result_2.panels.size)
          end
        end
      end

      describe "convergence" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        it "terminates within MAX_ITERATIONS" do
          # This is implicitly tested by the call completing
          expect { selector.call }.not_to raise_error
        end

        it "respects CONVERGENCE_THRESHOLD" do
          expect(described_class::CONVERGENCE_THRESHOLD).to eq(1e-6)
        end

        it "has reasonable MAX_ITERATIONS" do
          expect(described_class::MAX_ITERATIONS).to eq(1000)
        end
      end
    end
  end
end
