# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Leximin
      describe FeasibilityChecker, type: :service do
        subject(:checker) { described_class.new(constraint_builder) }

        let(:constraint_builder) { ConstraintBuilder.new(sortition) }

        before { require_cbc! }

        describe "#check" do
          context "with a valid sortition" do
            let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

            it "returns feasible" do
              result = checker.check
              expect(result[:feasible]).to be true
              expect(result[:errors]).to be_empty
            end
          end

          context "with no participants" do
            let(:sortition) { create(:stratified_sortition, num_candidates: 10) }

            before do
              stratum = create(:stratum, stratified_sortition: sortition, name: { en: "Test" })
              create(:substratum, stratum:, name: { en: "A" }, max_quota_percentage: "50")
            end

            it "returns infeasible with pool error" do
              result = checker.check
              expect(result[:feasible]).to be false
              expect(result[:errors].join).to include("volunteers")
            end
          end

          context "with panel size larger than pool" do
            let(:sortition) do
              create_sortition_with_participants(
                num_participants: 5,
                panel_size: 10,
                strata_config: [
                  { name: "Gender", substrata: [{ name: "A", percentage: 100 }] },
                ],
                rspec_seed: @rspec_seed
              )
            end

            it "returns infeasible" do
              result = checker.check
              expect(result[:feasible]).to be false
              expect(result[:errors].join).to include("pool")
            end
          end

          context "with no strata configured" do
            let(:sortition) { create(:stratified_sortition, num_candidates: 10) }

            before do
              10.times do |i|
                create(:sample_participant,
                       decidim_stratified_sortition: sortition,
                       personal_data_1: "p#{i}")
              end
            end

            it "returns infeasible with categories error" do
              result = checker.check
              expect(result[:feasible]).to be false
              expect(result[:errors].join).to include("categories")
            end
          end

          context "with zero panel size" do
            let(:sortition) { create(:stratified_sortition, num_candidates: 0) }

            it "returns infeasible" do
              result = checker.check
              expect(result[:feasible]).to be false
              expect(result[:errors].join).to include("positive")
            end
          end
        end

        describe "#check_cross_strata_feasibility" do
          # Helper to create a sortition with controlled participant assignment per substratum.
          # assignments is: { substratum_object => number_of_participants }
          # Each participant is assigned to exactly one substratum per stratum.
          def create_sortition_with_controlled_assignments(panel_size:, strata_with_substrata:, assignments:)
            sortition = create(:stratified_sortition, num_candidates: panel_size)

            strata_objects = strata_with_substrata.map.with_index do |stratum_config, idx|
              stratum = create(:stratum,
                               stratified_sortition: sortition,
                               name: { en: stratum_config[:name] },
                               kind: "value",
                               position: idx)

              substrata = stratum_config[:substrata].map.with_index do |sub_config, sub_idx|
                create(:substratum,
                       stratum:,
                       name: { en: sub_config[:name] },
                       value: sub_config[:name],
                       max_quota_percentage: sub_config[:percentage].to_s,
                       position: sub_idx)
              end

              { stratum:, substrata: }
            end

            # Create participants and assign them to specific substrata
            participant_id_counter = 0
            assignments.each do |substratum_index_map, count|
              count.times do
                participant = create(:sample_participant,
                                     decidim_stratified_sortition: sortition,
                                     personal_data_1: "p_#{participant_id_counter}")
                participant_id_counter += 1

                substratum_index_map.each do |stratum_idx, substratum_idx|
                  stratum_data = strata_objects[stratum_idx]
                  create(:sample_participant_stratum,
                         decidim_stratified_sortitions_sample_participant: participant,
                         decidim_stratified_sortitions_stratum: stratum_data[:stratum],
                         decidim_stratified_sortitions_substratum: stratum_data[:substrata][substratum_idx],
                         raw_value: stratum_data[:substrata][substratum_idx].value)
                end
              end
            end

            sortition.reload
          end

          context "when a substratum max quota exceeds its volunteers" do
            # Panel: 20, Stratum "Age" has substratum "Young" at 40% → max_quota = ceil(0.4*20) = 8
            # But only 5 participants belong to "Young"
            let(:sortition) do
              create_sortition_with_controlled_assignments(
                panel_size: 20,
                strata_with_substrata: [
                  { name: "Gender", substrata: [{ name: "Male", percentage: 50 }, { name: "Female", percentage: 50 }] },
                  { name: "Age", substrata: [{ name: "Young", percentage: 40 }, { name: "Old", percentage: 60 }] },
                ],
                assignments: {
                  # { stratum_idx => substratum_idx } => count
                  { 0 => 0, 1 => 0 } => 5, # 5 Male+Young
                  { 0 => 0, 1 => 1 } => 5, # 5 Male+Old
                  { 0 => 1, 1 => 1 } => 10, # 10 Female+Old
                }
              )
            end

            it "returns infeasible with substratum_quota_exceeds_volunteers error" do
              result = checker.check
              expect(result[:feasible]).to be false
              expect(result[:errors].join).to include("Young")
              expect(result[:errors].join).to include("Age")
            end
          end

          context "when multiple substrata have quotas exceeding their volunteers" do
            # Panel: 10
            # "Male" at 50% → max_quota = ceil(0.5*10) = 5, but only 4 Male participants
            # "North" at 40% → max_quota = ceil(0.4*10) = 4, but only 3 North participants
            # Percentages within each stratum sum to ≤100%, so quota_consistency passes
            let(:sortition) do
              create_sortition_with_controlled_assignments(
                panel_size: 10,
                strata_with_substrata: [
                  { name: "Gender", substrata: [{ name: "Male", percentage: 50 }, { name: "Female", percentage: 50 }] },
                  { name: "Zone", substrata: [{ name: "North", percentage: 40 }, { name: "South", percentage: 60 }] },
                ],
                assignments: {
                  { 0 => 0, 1 => 0 } => 2, # 2 Male+North
                  { 0 => 0, 1 => 1 } => 2, # 2 Male+South  → total Male = 4
                  { 0 => 1, 1 => 0 } => 1, # 1 Female+North → total North = 3
                  { 0 => 1, 1 => 1 } => 15, # 15 Female+South
                }
              )
            end

            it "returns multiple errors" do
              result = checker.check
              expect(result[:feasible]).to be false
              quota_errors = result[:errors].select { |e| e.include?("quota") || e.include?("cuota") || e.include?("quota") }
              expect(quota_errors.size).to be >= 2
            end

            it "mentions both problematic substrata" do
              result = checker.check
              errors_text = result[:errors].join("; ")
              expect(errors_text).to include("Male")
              expect(errors_text).to include("North")
            end
          end

          context "when substratum has percentage 0 (unrestricted)" do
            # percentage 0 → max_quota = panel_size → should NOT trigger error even if few volunteers
            let(:sortition) do
              create_sortition_with_controlled_assignments(
                panel_size: 10,
                strata_with_substrata: [
                  { name: "Gender", substrata: [{ name: "Male", percentage: 50 }, { name: "Female", percentage: 50 }] },
                  { name: "Age", substrata: [{ name: "Young", percentage: 0 }, { name: "Old", percentage: 0 }] },
                ],
                assignments: {
                  { 0 => 0, 1 => 0 } => 2, # 2 Male+Young
                  { 0 => 0, 1 => 1 } => 3, # 3 Male+Old
                  { 0 => 1, 1 => 0 } => 2, # 2 Female+Young
                  { 0 => 1, 1 => 1 } => 3, # 3 Female+Old
                }
              )
            end

            it "does not flag substrata with percentage 0" do
              result = checker.check
              quota_errors = result[:errors].select { |e| e.include?("quota") || e.include?("cuota") }
              expect(quota_errors).to be_empty
            end
          end

          context "when there is only one stratum (skips cross-strata check)" do
            # Only 1 stratum → check_cross_strata_feasibility returns early
            let(:sortition) do
              create_sortition_with_controlled_assignments(
                panel_size: 10,
                strata_with_substrata: [
                  { name: "Gender", substrata: [{ name: "Male", percentage: 80 }, { name: "Female", percentage: 80 }] },
                ],
                assignments: {
                  { 0 => 0 } => 3, # 3 Male
                  { 0 => 1 } => 7, # 7 Female
                }
              )
            end

            it "does not run cross-strata check" do
              result = checker.check
              # The quota check might still catch issues, but not via cross-strata
              quota_exceeds_errors = result[:errors].select { |e| e.include?("volunteer(s) belong") || e.include?("voluntari") }
              expect(quota_exceeds_errors).to be_empty
            end
          end

          context "when quotas are within available volunteers (valid)" do
            # All substrata have enough volunteers for their max_quota
            let(:sortition) do
              create_sortition_with_controlled_assignments(
                panel_size: 10,
                strata_with_substrata: [
                  { name: "Gender", substrata: [{ name: "Male", percentage: 50 }, { name: "Female", percentage: 50 }] },
                  { name: "Age", substrata: [{ name: "Young", percentage: 30 }, { name: "Old", percentage: 70 }] },
                ],
                assignments: {
                  { 0 => 0, 1 => 0 } => 10, # 10 Male+Young
                  { 0 => 0, 1 => 1 } => 10, # 10 Male+Old
                  { 0 => 1, 1 => 0 } => 10, # 10 Female+Young
                  { 0 => 1, 1 => 1 } => 10, # 10 Female+Old
                }
              )
            end

            it "returns feasible" do
              result = checker.check
              expect(result[:feasible]).to be true
              expect(result[:errors]).to be_empty
            end
          end

          context "when ceil effect pushes quota above volunteers" do
            # Panel: 15, "Local" at 10% → max_quota = ceil(0.1*15) = 2, but only 1 volunteer
            let(:sortition) do
              create_sortition_with_controlled_assignments(
                panel_size: 15,
                strata_with_substrata: [
                  { name: "Gender", substrata: [{ name: "Male", percentage: 50 }, { name: "Female", percentage: 50 }] },
                  { name: "Origin", substrata: [{ name: "Local", percentage: 10 }, { name: "Foreign", percentage: 90 }] },
                ],
                assignments: {
                  { 0 => 0, 1 => 0 } => 1, # 1 Male+Local
                  { 0 => 0, 1 => 1 } => 7, # 7 Male+Foreign
                  { 0 => 1, 1 => 1 } => 7, # 7 Female+Foreign
                }
              )
            end

            it "detects the ceil-induced infeasibility" do
              result = checker.check
              expect(result[:feasible]).to be false
              expect(result[:errors].join).to include("Local")
            end
          end
        end
      end
    end
  end
end
