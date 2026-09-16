# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe SortitionResultsExportJob do
        subject(:job) { described_class.new }

        let(:organization) { instance_double(Decidim::Organization) }
        let(:user) { instance_double(Decidim::User, organization:) }
        let(:stratified_sortition) { instance_double(Decidim::StratifiedSortitions::StratifiedSortition, id: 123) }

        let(:csv_data) { instance_double(Decidim::Exporters::ExportData, extension: "csv") }
        let(:excel_data) { instance_double(Decidim::Exporters::ExportData, extension: "xlsx") }
        let(:json_data) { instance_double(Decidim::Exporters::ExportData, extension: "json") }
        let(:private_export) { instance_double(Decidim::PrivateExport) }
        let(:exporter_double) do
          instance_double(SortitionResultsExporter,
                          export_csv: csv_data,
                          export_excel: excel_data,
                          export_json: json_data)
        end

        let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

        before do
          allow(SortitionResultsExporter).to receive(:new).and_return(exporter_double)
          allow(job).to receive(:attach_archive).and_return(private_export)
          allow(Decidim::ExportMailer).to receive(:export).and_return(mailer_double)
        end

        describe ".queue_name" do
          it "is queued as :stratified_sortitions" do
            expect(described_class.queue_name).to eq("stratified_sortitions")
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

            it "creates a private export from csv and sends it to ExportMailer" do
              job.perform(user, stratified_sortition, "csv")

              expect(job).to have_received(:attach_archive).with(csv_data, "sortition_results_123", user, "sortition_results")
              expect(Decidim::ExportMailer).to have_received(:export).with(user, private_export)
            end

            it "delivers the email" do
              job.perform(user, stratified_sortition, "csv")
              expect(mailer_double).to have_received(:deliver_now)
            end
          end

          context "when format is 'excel'" do
            it "calls export_excel on the exporter" do
              job.perform(user, stratified_sortition, "excel")
              expect(exporter_double).to have_received(:export_excel)
            end

            it "creates a private export from xlsx and sends it to ExportMailer" do
              job.perform(user, stratified_sortition, "excel")

              expect(job).to have_received(:attach_archive).with(excel_data, "sortition_results_123", user, "sortition_results")
              expect(Decidim::ExportMailer).to have_received(:export).with(user, private_export)
            end
          end

          context "when format is 'json'" do
            it "calls export_json on the exporter" do
              job.perform(user, stratified_sortition, "json")
              expect(exporter_double).to have_received(:export_json)
            end

            it "creates a private export from json and sends it to ExportMailer" do
              job.perform(user, stratified_sortition, "json")

              expect(job).to have_received(:attach_archive).with(json_data, "sortition_results_123", user, "sortition_results")
              expect(Decidim::ExportMailer).to have_received(:export).with(user, private_export)
            end
          end

          context "when format is unknown" do
            it "falls back to csv" do
              job.perform(user, stratified_sortition, "pdf")
              expect(exporter_double).to have_received(:export_csv)
            end
          end

          it "uses 'sortition_results_<id>' as the private export name" do
            job.perform(user, stratified_sortition, "csv")

            expect(job).to have_received(:attach_archive).with(anything, "sortition_results_123", anything, "sortition_results")
          end

          it "passes the requesting user to the mailer" do
            job.perform(user, stratified_sortition, "csv")
            expect(Decidim::ExportMailer).to have_received(:export).with(user, private_export)
          end
        end
      end
    end
  end
end
