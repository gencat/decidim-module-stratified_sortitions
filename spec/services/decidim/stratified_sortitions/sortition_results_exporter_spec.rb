# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe SortitionResultsExporter, type: :service do
      subject(:exporter) { described_class.new(stratified_sortition) }

      let(:organization) { create(:organization) }
      let(:participatory_process) { create(:participatory_process, organization:) }
      let(:component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
      let(:stratified_sortition) { create(:stratified_sortition, component:) }

      let(:stratum) { create(:stratum, stratified_sortition:, kind: "value", name: { en: "Gender" }) }
      let!(:substratum_m) { create(:substratum, stratum:, name: { en: "Man" }, value: "M", max_quota_percentage: "50") }
      let!(:substratum_f) { create(:substratum, stratum:, name: { en: "Woman" }, value: "F", max_quota_percentage: "50") }

      let(:sample_import) { create(:sample_import, stratified_sortition:) }

      let!(:participant_1) do
        create(:sample_participant,
               decidim_stratified_sortition: stratified_sortition,
               decidim_stratified_sortitions_sample_import: sample_import,
               personal_data_1: "ID001", personal_data_2: "Alice", personal_data_3: "A", personal_data_4: "X")
      end
      let!(:participant_2) do
        create(:sample_participant,
               decidim_stratified_sortition: stratified_sortition,
               decidim_stratified_sortitions_sample_import: sample_import,
               personal_data_1: "ID002", personal_data_2: "Bob", personal_data_3: "B", personal_data_4: "Y")
      end

      let!(:participant_stratum_one) do
        create(:sample_participant_stratum,
               decidim_stratified_sortitions_sample_participant: participant_1,
               decidim_stratified_sortitions_stratum: stratum,
               decidim_stratified_sortitions_substratum: substratum_f)
      end
      let!(:participant_stratum_two) do
        create(:sample_participant_stratum,
               decidim_stratified_sortitions_sample_participant: participant_2,
               decidim_stratified_sortitions_stratum: stratum,
               decidim_stratified_sortitions_substratum: substratum_m)
      end

      let!(:portfolio) do
        create(:panel_portfolio,
               stratified_sortition:,
               panels: [[participant_1.id, participant_2.id]],
               probabilities: [1.0],
               selection_probabilities: { participant_1.id => 1.0, participant_2.id => 1.0 },
               selected_panel_index: 0,
               selected_at: Time.current,
               verification_seed: "test_seed",
               random_value_used: 0.42)
      end

      # -----------------------------------------------------------------------
      # export_csv
      # -----------------------------------------------------------------------
      describe "#export_csv" do
        subject(:result) { exporter.export_csv }

        it "returns an ExportData object" do
          expect(result).to be_a(Decidim::Exporters::ExportData)
        end

        it "uses the csv extension" do
          expect(result.extension).to eq("csv")
        end

        it "produces non-empty content" do
          expect(result.read).not_to be_empty
        end

        describe "CSV structure" do
          let(:rows) { CSV.parse(result.read, col_sep: Decidim.default_csv_col_sep) }

          it "has metadata headers in the first row" do
            expect(rows[0]).to include("Algorithm")
            expect(rows[0]).to include("Total participants")
          end

          it "has metadata values in the second row" do
            # algorithm value is "LEXIMIN v1.0"
            expect(rows[1][0]).to match(/LEXIMIN/)
          end

          it "has a blank third row" do
            expect(rows[2]).to all(be_nil.or(be_empty))
          end

          it "has participant headers in the fourth row" do
            expect(rows[3]).to include("Personal data 1 (unique identifier)")
            expect(rows[3]).to include("Personal data 2")
          end

          it "has a stratum column header derived from stratum name" do
            expect(rows[3]).to include("Gender")
          end

          it "has participant data starting at the fifth row" do
            personal_ids = rows[4..].map { |row| row[0] }
            expect(personal_ids).to include("ID001")
            expect(personal_ids).to include("ID002")
          end

          it "includes substratum names in the stratum column" do
            stratum_col_idx = rows[3].index("Gender")
            substratum_values = rows[4..].map { |row| row[stratum_col_idx] }
            expect(substratum_values).to include("Woman")
            expect(substratum_values).to include("Man")
          end
        end
      end

      # -----------------------------------------------------------------------
      # export_excel
      # -----------------------------------------------------------------------
      describe "#export_excel" do
        subject(:result) { exporter.export_excel }

        it "returns an ExportData object" do
          expect(result).to be_a(Decidim::Exporters::ExportData)
        end

        it "uses the xlsx extension" do
          expect(result.extension).to eq("xlsx")
        end

        it "produces non-empty binary content" do
          expect(result.read.bytesize).to be > 0
        end

        it "produces valid XLSX binary data (PK magic bytes)" do
          # XLSX is a ZIP file; ZIP files start with PK (0x50 0x4B)
          expect(result.read.b[0, 2]).to eq("PK")
        end
      end

      # -----------------------------------------------------------------------
      # export_json
      # -----------------------------------------------------------------------
      describe "#export_json" do
        subject(:result) { exporter.export_json }

        it "returns an ExportData object" do
          expect(result).to be_a(Decidim::Exporters::ExportData)
        end

        it "uses the json extension" do
          expect(result.extension).to eq("json")
        end

        it "produces valid JSON" do
          expect { JSON.parse(result.read) }.not_to raise_error
        end

        describe "JSON structure" do
          let(:parsed) { JSON.parse(result.read) }

          it "has a metadata key" do
            expect(parsed).to have_key("metadata")
          end

          it "has a participants key" do
            expect(parsed).to have_key("participants")
          end

          it "has algorithm in metadata" do
            expect(parsed["metadata"]["Algorithm"]).to match(/LEXIMIN/)
          end

          it "includes all selected participants" do
            expect(parsed["participants"].size).to eq(2)
          end

          it "includes personal_data_1 for each participant" do
            ids = parsed["participants"].map { |p| p["Personal data 1 (unique identifier)"] }
            expect(ids).to include("ID001", "ID002")
          end

          it "includes stratum substratum values for each participant" do
            genders = parsed["participants"].map { |p| p["Gender"] }
            expect(genders).to include("Woman", "Man")
          end
        end
      end
    end
  end
end
