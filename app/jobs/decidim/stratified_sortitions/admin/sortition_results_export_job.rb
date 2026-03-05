# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Background job that generates a sortition results export and sends it
      # to the requesting user as a zipped email attachment.
      # Follows the same pattern as Decidim::ExportJob in decidim-core.
      class SortitionResultsExportJob < ApplicationJob
        queue_as :exports

        def perform(user, stratified_sortition, format)
          exporter = SortitionResultsExporter.new(stratified_sortition)

          export_data = case format
                        when "excel" then exporter.export_excel
                        when "json" then exporter.export_json
                        else exporter.export_csv
                        end

          export_name = "sortition_results_#{stratified_sortition.id}"

          Decidim::ExportMailer.export(user, export_name, export_data).deliver_later
        end
      end
    end
  end
end
