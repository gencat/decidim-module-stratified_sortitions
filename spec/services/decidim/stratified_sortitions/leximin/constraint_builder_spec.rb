# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Leximin
      describe ConstraintBuilder, type: :service do
        subject(:builder) { described_class.new(sortition) }

        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        before { require_cbc! }

        describe "#panel_size" do
          it "returns the num_candidates from sortition" do
            expect(builder.panel_size).to eq(10)
          end
        end

        describe "#volunteer_ids" do
          it "returns all participant IDs" do
            expect(builder.volunteer_ids.size).to eq(50)
          end

          it "contains valid participant IDs" do
            valid_ids = sortition.sample_participants.pluck(:id)
            expect(builder.volunteer_ids).to match_array(valid_ids)
          end
        end

        describe "#num_volunteers" do
          it "returns the count of volunteers" do
            expect(builder.num_volunteers).to eq(50)
          end
        end

        describe "#category_ids" do
          it "returns all substratum IDs" do
            # 2 strata: Gender (2 substrata) + Age (3 substrata) = 5 categories
            expect(builder.category_ids.size).to eq(5)
          end
        end

        describe "#quotas" do
          it "returns quotas for each category" do
            expect(builder.quotas.keys).to match_array(builder.category_ids)
          end

          it "has min quota of 0 for all categories" do
            builder.quotas.each_value do |quota|
              expect(quota[:min]).to eq(0)
            end
          end

          it "calculates max quota from percentage" do
            # With panel_size=10 and 50% quota, max should be ceil(0.5 * 10) = 5
            gender_substrata = sortition.strata.find_by(name: { "en" => "Gender" }).substrata
            gender_substrata.each do |sub|
              quota = builder.quotas[sub.id]
              expected_max = (sub.max_quota_percentage.to_f / 100.0 * 10).ceil
              expect(quota[:max]).to eq(expected_max)
            end
          end
        end

        describe "#volunteer_categories" do
          it "maps each volunteer to their categories" do
            builder.volunteer_ids.each do |vid|
              categories = builder.volunteer_categories[vid]
              # Each volunteer should be in 2 categories (one per stratum)
              expect(categories.size).to eq(2)
            end
          end
        end

        describe "#category_volunteers" do
          it "maps each category to its volunteers" do
            builder.category_ids.each do |cat_id|
              volunteers = builder.category_volunteers[cat_id]
              expect(volunteers).not_to be_empty
            end
          end

          it "has total assignments matching volunteers * strata" do
            total_assignments = builder.category_ids.sum { |cid| builder.category_volunteers[cid].size }
            # 50 volunteers * 2 strata = 100 total assignments
            expect(total_assignments).to eq(50 * 2)
          end
        end

        describe "#volunteer_index" do
          it "returns unique indices for each volunteer" do
            indices = builder.volunteer_ids.map { |vid| builder.volunteer_index(vid) }
            expect(indices.uniq.size).to eq(indices.size)
          end

          it "returns indices in range 0 to n-1" do
            indices = builder.volunteer_ids.map { |vid| builder.volunteer_index(vid) }
            expect(indices.min).to eq(0)
            expect(indices.max).to eq(49)
          end
        end

        describe "#strata_info" do
          it "returns information about all strata" do
            expect(builder.strata_info.size).to eq(2)
          end

          it "includes substrata information" do
            gender_info = builder.strata_info.find { |s| s[:name]["en"] == "Gender" }
            expect(gender_info[:substrata].size).to eq(2)
          end
        end
      end
    end
  end
end
