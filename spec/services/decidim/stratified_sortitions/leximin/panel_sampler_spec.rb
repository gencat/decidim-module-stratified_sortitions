# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Leximin
      describe PanelSampler, type: :service do
        describe "#sample" do
          let(:panels) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }
          let(:probabilities) { [0.5, 0.3, 0.2] }
          subject(:sampler) { described_class.new(panels, probabilities, random_seed:) }
          let(:random_seed) { nil }

          context "with valid panels and probabilities" do
            it "returns a successful result" do
              result = sampler.sample
              expect(result.success?).to be true
            end

            it "returns a panel from the list" do
              result = sampler.sample
              expect(panels).to include(result.selected_panel)
            end

            it "returns a valid index" do
              result = sampler.sample
              expect(result.selected_index).to be_between(0, panels.size - 1)
            end

            it "returns the random value used" do
              result = sampler.sample
              expect(result.random_value).to be_between(0, 1).exclusive
            end
          end

          context "with deterministic seed" do
            let(:random_seed) { 12_345 }

            it "produces reproducible results" do
              result_1 = described_class.new(panels, probabilities, random_seed: 12_345).sample
              result_2 = described_class.new(panels, probabilities, random_seed: 12_345).sample

              expect(result_1.selected_panel).to eq(result_2.selected_panel)
              expect(result_1.selected_index).to eq(result_2.selected_index)
              expect(result_1.random_value).to eq(result_2.random_value)
            end

            it "produces different results with different seeds" do
              results = (1..10).map do |seed|
                described_class.new(panels, probabilities, random_seed: seed).sample.selected_index
              end

              # With different seeds, we should see some variation
              expect(results.uniq.size).to be > 1
            end
          end

          context "with RSpec seed" do
            let(:random_seed) { @rspec_seed || RSpec.configuration.seed }

            it "produces consistent results within same test run" do
              sampler_1 = described_class.new(panels, probabilities, random_seed:)
              sampler_2 = described_class.new(panels, probabilities, random_seed:)

              expect(sampler_1.sample.selected_panel).to eq(sampler_2.sample.selected_panel)
            end
          end

          context "with empty panels" do
            let(:panels) { [] }
            let(:probabilities) { [] }

            it "returns an error result" do
              result = sampler.sample
              expect(result.success?).to be false
              expect(result.error).to include("panels")
            end
          end

          context "with mismatched sizes" do
            let(:probabilities) { [0.5, 0.5] } # Only 2 probabilities for 3 panels

            it "returns an error result" do
              result = sampler.sample
              expect(result.success?).to be false
              expect(result.error).to include("coincideixen")
            end
          end

          context "with unnormalized probabilities" do
            let(:probabilities) { [2.0, 1.0, 1.0] } # Sum = 4, not 1

            it "normalizes and samples correctly" do
              result = sampler.sample
              expect(result.success?).to be true
              expect(panels).to include(result.selected_panel)
            end
          end

          context "with zero probabilities" do
            let(:probabilities) { [0, 0, 0] }

            it "falls back to uniform distribution" do
              result = sampler.sample
              expect(result.success?).to be true
              expect(panels).to include(result.selected_panel)
            end
          end

          context "with single panel" do
            let(:panels) { [[1, 2, 3]] }
            let(:probabilities) { [1.0] }

            it "always selects the only panel" do
              10.times do
                result = described_class.new(panels, probabilities).sample
                expect(result.selected_panel).to eq([1, 2, 3])
                expect(result.selected_index).to eq(0)
              end
            end
          end
        end

        describe "#sample_multiple" do
          let(:panels) { [[1, 2, 3], [4, 5, 6]] }
          let(:probabilities) { [0.5, 0.5] }
          subject(:sampler) { described_class.new(panels, probabilities) }

          it "returns the requested number of samples" do
            results = sampler.sample_multiple(5)
            expect(results.size).to eq(5)
          end

          it "returns all successful results" do
            results = sampler.sample_multiple(5)
            expect(results).to all(be_success)
          end
        end

        describe "#cumulative_distribution" do
          let(:panels) { [[1], [2], [3]] }
          let(:probabilities) { [0.2, 0.5, 0.3] }
          subject(:sampler) { described_class.new(panels, probabilities) }

          it "returns cumulative probabilities" do
            cdf = sampler.cumulative_distribution
            expect(cdf).to eq([0.2, 0.7, 1.0])
          end
        end

        describe "statistical distribution" do
          let(:panels) { [[1], [2], [3]] }
          let(:probabilities) { [0.5, 0.3, 0.2] }
          let(:num_samples) { 1000 }

          it "samples according to specified probabilities (approximately)" do
            counts = Hash.new(0)

            num_samples.times do
              result = described_class.new(panels, probabilities).sample
              counts[result.selected_index] += 1
            end

            # Check that empirical frequencies are close to specified probabilities
            # With 1000 samples, we expect reasonable approximation
            expect(counts[0].to_f / num_samples).to be_within(0.1).of(0.5)
            expect(counts[1].to_f / num_samples).to be_within(0.1).of(0.3)
            expect(counts[2].to_f / num_samples).to be_within(0.1).of(0.2)
          end
        end
      end
    end
  end
end
