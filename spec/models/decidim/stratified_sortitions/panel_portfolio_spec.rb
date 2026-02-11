# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe PanelPortfolio, type: :model do
      subject(:portfolio) { create(:panel_portfolio, stratified_sortition: sortition) }

      let(:sortition) { create(:stratified_sortition) }

      describe "validations" do
        it "is valid with valid attributes" do
          expect(portfolio).to be_valid
        end

        it "requires panels" do
          portfolio.panels = nil
          expect(portfolio).not_to be_valid
        end

        it "requires probabilities" do
          portfolio.probabilities = nil
          expect(portfolio).not_to be_valid
        end

        it "requires generated_at" do
          portfolio.generated_at = nil
          expect(portfolio).not_to be_valid
        end

        it "validates panels and probabilities have same size" do
          portfolio.panels = [[1, 2], [3, 4], [5, 6]]
          portfolio.probabilities = [0.5, 0.5] # Only 2 probabilities for 3 panels
          expect(portfolio).not_to be_valid
          expect(portfolio.errors[:probabilities]).to be_present
        end

        it "validates probabilities sum to 1" do
          portfolio.probabilities = [0.3, 0.3] # Sums to 0.6
          portfolio.panels = [[1], [2]]
          expect(portfolio).not_to be_valid
          expect(portfolio.errors[:probabilities]).to be_present
        end

        it "allows probabilities summing to approximately 1" do
          portfolio.probabilities = [0.333, 0.333, 0.334] # Sums to 1.0
          portfolio.panels = [[1], [2], [3]]
          expect(portfolio).to be_valid
        end
      end

      describe "associations" do
        it "belongs to stratified_sortition" do
          expect(portfolio.stratified_sortition).to eq(sortition)
        end
      end

      describe "#sampled?" do
        it "returns false when not sampled" do
          expect(portfolio.sampled?).to be false
        end

        it "returns true when sampled" do
          portfolio.update!(selected_panel_index: 0, selected_at: Time.current)
          expect(portfolio.sampled?).to be true
        end
      end

      describe "#selected_panel" do
        it "returns nil when not sampled" do
          expect(portfolio.selected_panel).to be_nil
        end

        it "returns the selected panel when sampled" do
          portfolio.update!(selected_panel_index: 0, selected_at: Time.current)
          expect(portfolio.selected_panel).to eq([1, 2, 3])
        end

        it "returns correct panel for different indices" do
          portfolio.update!(selected_panel_index: 1, selected_at: Time.current)
          expect(portfolio.selected_panel).to eq([4, 5, 6])
        end
      end

      describe "#selected_panel_probability" do
        it "returns nil when not sampled" do
          expect(portfolio.selected_panel_probability).to be_nil
        end

        it "returns the probability of selected panel" do
          portfolio.update!(selected_panel_index: 0, selected_at: Time.current)
          expect(portfolio.selected_panel_probability).to eq(0.6)
        end
      end

      describe "#sample!" do
        before { require_cbc! }

        it "samples and updates the portfolio" do
          result = portfolio.sample!(verification_seed: "test_seed")

          expect(result.success?).to be true
          expect(portfolio.sampled?).to be true
          expect(portfolio.selected_panel_index).to be_present
          expect(portfolio.selected_at).to be_present
        end

        it "stores the verification seed" do
          portfolio.sample!(verification_seed: "my_seed")
          expect(portfolio.verification_seed).to eq("my_seed")
        end

        it "stores the random value used" do
          portfolio.sample!(verification_seed: "test")
          expect(portfolio.random_value_used).to be_present
        end

        it "raises error if already sampled" do
          portfolio.sample!
          expect { portfolio.sample! }.to raise_error(RuntimeError, /already sampled/)
        end

        it "produces reproducible results with same seed" do
          portfolio_1 = create(:panel_portfolio, stratified_sortition: create(:stratified_sortition))
          portfolio_2 = create(:panel_portfolio,
                               stratified_sortition: create(:stratified_sortition),
                               panels: portfolio_1.panels,
                               probabilities: portfolio_1.probabilities)

          portfolio_1.sample!(verification_seed: "same_seed")
          portfolio_2.sample!(verification_seed: "same_seed")

          expect(portfolio_1.selected_panel_index).to eq(portfolio_2.selected_panel_index)
          expect(portfolio_1.random_value_used).to eq(portfolio_2.random_value_used)
        end
      end

      describe "#selected_participants" do
        let(:sortition) { create_simple_sortition(num_participants: 10, panel_size: 3, rspec_seed: 12_345) }

        before { require_cbc! }

        context "when not sampled" do
          it "returns empty array" do
            portfolio = create(:panel_portfolio, stratified_sortition: sortition)
            expect(portfolio.selected_participants).to be_empty
          end
        end

        context "when sampled with real participants" do
          let(:real_portfolio) do
            service = FairSortitionService.new(sortition)
            service.call
            sortition.reload.panel_portfolio
          end

          it "returns SampleParticipant records" do
            expect(real_portfolio.selected_participants).to all(be_a(SampleParticipant))
          end

          it "returns correct number of participants" do
            expect(real_portfolio.selected_participants.size).to eq(3)
          end
        end
      end

      describe "#num_panels" do
        it "returns count of panels" do
          expect(portfolio.num_panels).to eq(2)
        end

        it "returns 0 for nil panels" do
          portfolio.panels = nil
          expect(portfolio.num_panels).to eq(0)
        end
      end

      describe "#fairness_metrics" do
        it "returns metrics hash" do
          metrics = portfolio.fairness_metrics

          expect(metrics).to have_key(:min_probability)
          expect(metrics).to have_key(:max_probability)
          expect(metrics).to have_key(:mean_probability)
          expect(metrics).to have_key(:probability_range)
        end

        it "calculates correct values" do
          portfolio.selection_probabilities = { 1 => 0.2, 2 => 0.4, 3 => 0.6 }
          metrics = portfolio.fairness_metrics

          expect(metrics[:min_probability]).to eq(0.2)
          expect(metrics[:max_probability]).to eq(0.6)
          expect(metrics[:mean_probability]).to be_within(0.001).of(0.4)
          expect(metrics[:probability_range]).to be_within(0.001).of(0.4)
        end

        it "returns empty hash for empty probabilities" do
          portfolio.selection_probabilities = {}
          expect(portfolio.fairness_metrics).to be_empty
        end
      end

      describe "#audit_log" do
        it "returns comprehensive audit information" do
          log = portfolio.audit_log

          expect(log[:algorithm]).to eq("LEXIMIN")
          expect(log[:version]).to eq("1.0")
          expect(log[:stratified_sortition_id]).to eq(sortition.id)
          expect(log[:generated_at]).to be_present
          expect(log[:num_panels]).to eq(2)
          expect(log[:sampled]).to be false
        end

        it "includes sampling info when sampled" do
          portfolio.update!(
            selected_panel_index: 0,
            selected_at: Time.current,
            verification_seed: "audit_seed",
            random_value_used: 0.42
          )

          log = portfolio.audit_log

          expect(log[:sampled]).to be true
          expect(log[:selected_panel_index]).to eq(0)
          expect(log[:verification_seed]).to eq("audit_seed")
          expect(log[:random_value_used]).to eq(0.42)
        end
      end

      describe "factory traits" do
        it "creates sampled portfolio with :sampled trait" do
          sampled = create(:panel_portfolio, :sampled, stratified_sortition: sortition)

          expect(sampled.sampled?).to be true
          expect(sampled.selected_panel_index).to eq(0)
          expect(sampled.verification_seed).to eq("test_seed")
        end
      end
    end
  end
end
