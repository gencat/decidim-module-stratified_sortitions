# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe SortitionResultsExportJob do
        subject(:job) { described_class.new }

        let(:organization) { create(:organization) }
        let(:user) { create(:user, :admin, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
        let(:stratified_sortition) { create(:stratified_sortition, component:) }

        let(:csv_data) { instance_double(Decidim::Exporters::ExportData, extension: "csv") }
        let(:excel_data) { instance_double(Decidim::Exporters::ExportData, extension: "xlsx") }
        let(:json_data) { instance_double(Decidim::Exporters::ExportData, extension: "json") }
        let(:exporter_double) do
          instance_double(SortitionResultsExporter,
                          export_csv: csv_data,
                          export_excel: excel_data,
                          export_json: json_data)
        end

        let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

        before do
          allow(SortitionResultsExporter).to receive(:new).and_return(exporter_double)
          allow(Decidim::ExportMailer).to receive(:export).and_return(mailer_double)
        end

        describe ".queue_name" do
          it "is queued as :exports" do
            expect(described_class.queue_name).to eq("exports")
          end
        end

        describe "#perform" do
          it "instantiates SortitionResultsExporter with the sortition" do
            job.perform(user, stratified_sortition, "csv")
            expect(SortitionResultsExporter).to have_received(:new).with(stratified_sortition)
          end

          context "when format is 'csv'" do
            it "calls export_csv on the exporter" do
              job.perform(user, stratified_sortition, "csv")
              expect(exporter_double).to have_received(:export_csv)
            end

            it "sends the csv data to ExportMailer" do
              job.perform(user, stratified_sortition, "csv")

              expect(Decidim::ExportMailer).to have_received(:export) do |_u, _name, data|
                expect(data.extension).to eq("csv")
              end
            end

            it "delivers the email" do
              job.perform(user, stratified_sortition, "csv")
              expect(mailer_double).to have_received(:deliver_later)
            end
          end

          context "when format is 'excel'" do
            it "calls export_excel on the exporter" do
              job.perform(user, stratified_sortition, "excel")
              expect(exporter_double).to have_received(:export_excel)
            end

            it "sends the xlsx data to ExportMailer" do
              job.perform(user, stratified_sortition, "excel")

              expect(Decidim::ExportMailer).to have_received(:export) do |_u, _name, data|
                expect(data.extension).to eq("xlsx")
              end
            end
          end

          context "when format is 'json'" do
            it "calls export_json on the exporter" do
              job.perform(user, stratified_sortition, "json")
              expect(exporter_double).to have_received(:export_json)
            end

            it "sends the json data to ExportMailer" do
              job.perform(user, stratified_sortition, "json")

              expect(Decidim::ExportMailer).to have_received(:export) do |_u, _name, data|
                expect(data.extension).to eq("json")
              end
            end
          end

          context "when format is unknown" do
            it "falls back to csv" do
              job.perform(user, stratified_sortition, "pdf")
              expect(exporter_double).to have_received(:export_csv)
            end
          end

          it "uses 'sortition_results_<id>' as the export name" do
            job.perform(user, stratified_sortition, "csv")

            expect(Decidim::ExportMailer).to have_received(:export).with(
              anything,
              "sortition_results_#{stratified_sortition.id}",
              anything
            )
          end

          it "passes the requesting user to the mailer" do
            job.perform(user, stratified_sortition, "csv")
            expect(Decidim::ExportMailer).to have_received(:export).with(user, anything, anything)
          end
        end
      end
    end
  end
end
