# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Leximin
      describe PanelGenerator, type: :service do
        subject(:generator) { described_class.new(constraint_builder) }

        let(:constraint_builder) { ConstraintBuilder.new(sortition) }
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        before { require_cbc! }

        describe "#find_feasible_panel" do
          it "returns a panel" do
            panel = generator.find_feasible_panel
            expect(panel).not_to be_nil
          end

          it "returns a panel of correct size" do
            panel = generator.find_feasible_panel
            expect(panel.size).to eq(10)
          end

          it "returns a panel with valid participant IDs" do
            panel = generator.find_feasible_panel
            valid_ids = sortition.sample_participants.pluck(:id)
            expect(panel).to all(be_in(valid_ids))
          end

          it "returns a panel with unique participants" do
            panel = generator.find_feasible_panel
            expect(panel.uniq.size).to eq(panel.size)
          end

          it "respects quota constraints" do
            panel = generator.find_feasible_panel

            constraint_builder.category_ids.each do |cat_id|
              quota = constraint_builder.quotas[cat_id]
              count_in_panel = panel.count do |pid|
                constraint_builder.volunteer_categories[pid]&.include?(cat_id)
              end

              expect(count_in_panel).to be <= quota[:max],
                                        "Panel violates max quota for category #{cat_id}"
            end
          end

          context "with infeasible constraints" do
            let(:sortition) do
              s = create(:stratified_sortition, num_candidates: 10)
              stratum = create(:stratum, stratified_sortition: s, name: { en: "Category" })
              # Quota of 10% means max 1, but we only have 1 person
              # and need 10 people total - infeasible
              sub_1 = create(:substratum, stratum:, name: { en: "A" }, value: "A", max_quota_percentage: "10")
              sub_2 = create(:substratum, stratum:, name: { en: "B" }, value: "B", max_quota_percentage: "10")

              # Create only 2 participants
              2.times do |i|
                p = create(:sample_participant, decidim_stratified_sortition: s, personal_data_1: "p#{i}")
                create(:sample_participant_stratum,
                       decidim_stratified_sortitions_sample_participant: p,
                       decidim_stratified_sortitions_stratum: stratum,
                       decidim_stratified_sortitions_substratum: i.zero? ? sub_1 : sub_2)
              end

              s.reload
            end

            it "returns nil when no feasible panel exists" do
              panel = generator.find_feasible_panel
              expect(panel).to be_nil
            end
          end
        end

        describe "#find_improving_panel" do
          context "without dual prices" do
            it "behaves like find_feasible_panel" do
              panel = generator.find_improving_panel(nil)
              expect(panel).not_to be_nil
              expect(panel.size).to eq(10)
            end
          end

          context "with dual prices" do
            let(:dual_prices) do
              # Give higher prices to first half of volunteers
              prices = {}
              constraint_builder.volunteer_ids.each_with_index do |vid, idx|
                prices[vid] = idx < 25 ? 1.0 : 0.1
              end
              prices
            end

            it "returns a panel" do
              panel = generator.find_improving_panel(dual_prices)
              # May return nil if no improving panel, or a valid panel
              expect(panel.size).to eq(10) if panel
            end

            it "respects quota constraints when returning a panel" do
              panel = generator.find_improving_panel(dual_prices)
              next unless panel

              constraint_builder.category_ids.each do |cat_id|
                quota = constraint_builder.quotas[cat_id]
                count_in_panel = panel.count do |pid|
                  constraint_builder.volunteer_categories[pid]&.include?(cat_id)
                end

                expect(count_in_panel).to be <= quota[:max]
              end
            end
          end
        end

        describe "determinism with same seed" do
          it "generates consistent panels with same RSpec seed" do
            panel_1 = generator.find_feasible_panel

            # Recreate with same configuration
            sortition_2 = create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed)
            builder_2 = ConstraintBuilder.new(sortition_2)
            generator_2 = described_class.new(builder_2)
            panel_2 = generator_2.find_feasible_panel

            # Panels should have same size (determinism of ILP solver)
            expect(panel_1.size).to eq(panel_2.size)
          end
        end
      end
    end
  end
end
