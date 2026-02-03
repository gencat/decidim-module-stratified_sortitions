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
              expect(result[:errors].join).to include("voluntaris")
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
              expect(result[:errors].join).to include("positiu")
            end
          end
        end
      end
    end
  end
end
