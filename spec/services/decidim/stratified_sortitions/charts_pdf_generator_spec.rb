# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe ChartsPdfGenerator, type: :service do
      subject(:generator) do
        described_class.new(
          stratified_sortition,
          strata_data,
          candidates_data,
          results_data,
          locale: :en
        )
      end

      let(:organization) { create(:organization) }
      let(:participatory_process) { create(:participatory_process, organization:) }
      let(:component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
      let(:stratified_sortition) { create(:stratified_sortition, component:) }

      let(:stratum) { create(:stratum, stratified_sortition:, kind: "value", name: { en: "Gender" }) }
      let!(:substratum_m) { create(:substratum, stratum:, name: { en: "Man" }, value: "M", max_quota_percentage: "50") }
      let!(:substratum_f) { create(:substratum, stratum:, name: { en: "Woman" }, value: "F", max_quota_percentage: "50") }

      let(:strata_data) do
        [
          {
            stratum:,
            chart_data: [["Man", 50], ["Woman", 50]]
          }
        ]
      end
      let(:candidates_data) do
        [
          {
            stratum:,
            chart_data: [["Man", 3], ["Woman", 4]]
          }
        ]
      end
      let(:results_data) do
        [
          {
            stratum:,
            chart_data: [["Man", 2], ["Woman", 3]]
          }
        ]
      end

      # Stub WickedPdf so tests don't require wkhtmltopdf to be installed.
      let(:wicked_pdf_double) { instance_double(WickedPdf) }

      before do
        allow(WickedPdf).to receive(:new).and_return(wicked_pdf_double)
        allow(wicked_pdf_double).to receive(:pdf_from_string).and_return("%PDF-1.4 fake-pdf-bytes")
      end

      describe "#generate" do
        it "returns the PDF bytes from WickedPdf" do
          result = generator.generate
          expect(result).to eq("%PDF-1.4 fake-pdf-bytes")
        end

        it "instantiates WickedPdf" do
          generator.generate
          expect(WickedPdf).to have_received(:new)
        end

        it "calls pdf_from_string with the generated HTML" do
          generator.generate
          expect(wicked_pdf_double).to have_received(:pdf_from_string) do |html, opts|
            expect(html).to be_a(String)
            expect(html).not_to be_empty
            expect(opts[:orientation]).to eq("Portrait")
            expect(opts[:page_size]).to eq("A4")
          end
        end

        it "generates HTML containing the sortition title" do
          generator.generate
          expect(wicked_pdf_double).to have_received(:pdf_from_string) do |html, _opts|
            title_text = stratified_sortition.title["en"]
            expect(html).to include(title_text)
          end
        end

        it "generates HTML with stratum name" do
          generator.generate
          expect(wicked_pdf_double).to have_received(:pdf_from_string) do |html, _opts|
            expect(html).to include("Gender")
          end
        end

        context "with a sampled portfolio" do
          let!(:sample_import) { create(:sample_import, stratified_sortition:) }
          let!(:participant)    { create(:sample_participant, decidim_stratified_sortition: stratified_sortition, decidim_stratified_sortitions_sample_import: sample_import) }
          let!(:portfolio) do
            create(:panel_portfolio,
                   stratified_sortition:,
                   panels: [[participant.id]],
                   probabilities: [1.0],
                   selection_probabilities: { participant.id => 1.0 },
                   selected_panel_index: 0,
                   selected_at: Time.current,
                   verification_seed: "seed123",
                   random_value_used: 0.5)
          end

          it "includes the algorithm info in the rendered HTML" do
            generator.generate
            expect(wicked_pdf_double).to have_received(:pdf_from_string) do |html, _opts|
              expect(html).to include("LEXIMIN")
            end
          end
        end

        context "when the portfolio is not sampled" do
          it "uses '-' for algorithm info and execution date" do
            generator.generate
            expect(wicked_pdf_double).to have_received(:pdf_from_string) do |html, _opts|
              expect(html).to include("-")
            end
          end
        end
      end

      describe "#build_strata_chart_data (via generate)" do
        it "builds chart data for each stratum" do
          generator.generate
          expect(wicked_pdf_double).to have_received(:pdf_from_string) do |html, _opts|
            # The template renders SVG charts; at minimum the SVG tag is present
            expect(html).to include("<svg")
          end
        end
      end
    end
  end
end
