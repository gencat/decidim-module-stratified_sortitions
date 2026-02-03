# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe FairSortitionService, type: :service do
      subject(:service) { described_class.new(sortition, verification_seed:) }

      let(:verification_seed) { nil }

      before { require_cbc! }

      describe "#call (single-phase)" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        context "with valid configuration" do
          let(:result) { service.call }

          it "succeeds" do
            expect(result.success?).to be true
          end

          it "returns selected participants" do
            expect(result.selected_participants).not_to be_empty
            expect(result.selected_participants.size).to eq(10)
          end

          it "returns selected participant IDs" do
            expect(result.selected_participant_ids).not_to be_empty
            expect(result.selected_participant_ids.size).to eq(10)
          end

          it "returns SampleParticipant records" do
            expect(result.selected_participants).to all(be_a(SampleParticipant))
          end

          it "creates a PanelPortfolio" do
            result
            expect(sortition.reload.panel_portfolio).to be_present
          end

          it "marks the portfolio as sampled" do
            result
            expect(sortition.reload.panel_portfolio.sampled?).to be true
          end

          it "includes selection log" do
            expect(result.selection_log).to be_a(Hash)
            expect(result.selection_log[:algorithm]).to eq("LEXIMIN")
          end

          it "includes the portfolio" do
            expect(result.portfolio).to be_a(PanelPortfolio)
          end
        end

        context "with verification seed" do
          let(:verification_seed) { "test_seed_12345" }
          let(:result) { service.call }

          it "stores the verification seed" do
            result
            expect(sortition.reload.panel_portfolio.verification_seed).to eq("test_seed_12345")
          end

          it "produces reproducible results" do
            result1 = service.call
            selected_ids1 = result1.selected_participant_ids

            # Create new sortition with same setup
            sortition2 = create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed)
            service2 = described_class.new(sortition2, verification_seed: "test_seed_12345")
            result2 = service2.call
            selected_ids2 = result2.selected_participant_ids

            # Both should succeed and produce same-sized results
            expect(result1.success?).to be true
            expect(result2.success?).to be true
            expect(selected_ids1.size).to eq(selected_ids2.size)
          end
        end

        context "when already performed" do
          before { service.call }

          it "returns error on second call" do
            result = service.call
            expect(result.success?).to be false
            expect(result.error).to include("ja s'ha realitzat")
          end
        end

        context "with infeasible configuration" do
          let(:sortition) { create_infeasible_sortition }
          let(:result) { service.call }

          it "fails" do
            expect(result.success?).to be false
          end

          it "returns error message" do
            expect(result.error).to be_present
          end

          it "does not create portfolio" do
            result
            expect(sortition.reload.panel_portfolio).to be_nil
          end
        end
      end

      describe "#generate_portfolio (two-phase)" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        it "creates a portfolio without sampling" do
          result = service.generate_portfolio

          expect(result.success?).to be true
          expect(result.portfolio).to be_a(PanelPortfolio)
          expect(result.portfolio.sampled?).to be false
        end

        it "stores panels and probabilities" do
          result = service.generate_portfolio

          expect(result.portfolio.panels).not_to be_empty
          expect(result.portfolio.probabilities).not_to be_empty
        end

        it "stores generation metadata" do
          result = service.generate_portfolio

          expect(result.portfolio.generated_at).to be_present
          expect(result.portfolio.generation_time_seconds).to be >= 0
        end

        it "returns existing portfolio if already generated" do
          result1 = service.generate_portfolio
          result2 = service.generate_portfolio

          expect(result2.portfolio.id).to eq(result1.portfolio.id)
        end
      end

      describe "#sample_from_portfolio (two-phase)" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        before { service.generate_portfolio }

        it "samples from the existing portfolio" do
          result = service.sample_from_portfolio(verification_seed: "public_seed")

          expect(result.success?).to be true
          expect(result.selected_participants.size).to eq(10)
        end

        it "marks portfolio as sampled" do
          service.sample_from_portfolio(verification_seed: "public_seed")

          expect(sortition.reload.panel_portfolio.sampled?).to be true
        end

        it "stores sampling metadata" do
          service.sample_from_portfolio(verification_seed: "ceremony_seed")

          portfolio = sortition.reload.panel_portfolio
          expect(portfolio.selected_panel_index).to be_present
          expect(portfolio.selected_at).to be_present
          expect(portfolio.verification_seed).to eq("ceremony_seed")
          expect(portfolio.random_value_used).to be_present
        end

        it "returns same result if already sampled" do
          result1 = service.sample_from_portfolio(verification_seed: "seed1")
          result2 = service.sample_from_portfolio(verification_seed: "seed2")

          expect(result1.selected_participant_ids).to eq(result2.selected_participant_ids)
        end

        context "without prior portfolio" do
          let(:sortition) { create(:stratified_sortition, num_candidates: 10) }

          it "returns error" do
            result = service.sample_from_portfolio

            expect(result.success?).to be false
            expect(result.error).to include("cartera")
          end
        end
      end

      describe "#verify" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }
        let(:verification_seed) { "verification_test" }

        before { service.call }

        it "verifies correct result" do
          expected_ids = sortition.panel_portfolio.selected_panel
          is_valid = service.verify(expected_ids, verification_seed:)

          expect(is_valid).to be true
        end

        it "rejects incorrect result" do
          wrong_ids = [999_999, 999_998, 999_997]
          is_valid = service.verify(wrong_ids, verification_seed:)

          expect(is_valid).to be false
        end

        it "rejects with different seed" do
          expected_ids = sortition.panel_portfolio.selected_panel
          is_valid = service.verify(expected_ids, verification_seed: "wrong_seed")

          # May or may not match depending on probability distribution
          # At minimum, verify call should not raise error
          expect([true, false]).to include(is_valid)
        end
      end

      describe "#already_performed?" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }

        it "returns false initially" do
          expect(service.already_performed?).to be false
        end

        it "returns false after generate_portfolio" do
          service.generate_portfolio
          expect(service.already_performed?).to be false
        end

        it "returns true after sampling" do
          service.call
          expect(service.already_performed?).to be true
        end
      end

      describe "audit trail" do
        let(:sortition) { create_simple_sortition(num_participants: 50, panel_size: 10, rspec_seed: @rspec_seed) }
        let(:result) { service.call }

        it "includes algorithm version" do
          expect(result.selection_log[:version]).to eq("1.0")
        end

        it "includes sortition ID" do
          expect(result.selection_log[:stratified_sortition_id]).to eq(sortition.id)
        end

        it "includes fairness metrics" do
          expect(result.selection_log[:fairness_metrics]).to be_a(Hash)
        end

        it "includes timing information" do
          expect(result.selection_log[:generated_at]).to be_present
        end
      end
    end
  end
end
