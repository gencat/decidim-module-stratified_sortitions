# frozen_string_literal: true

require "csv"

module Decidim
  module StratifiedSortitions
    module Admin
      class ImportSampleJob < ApplicationJob
        queue_as :default

        def perform(file_content, filename, stratified_sortition, user)
          sample_import = Decidim::StratifiedSortitions::SampleImport.create!(
            stratified_sortition:,
            filename:,
            status: :processing
          )
          processing_errors = []
          total_rows = 0

          CSV.parse(file_content, headers: true, col_sep: ",") do |row|
            total_rows += 1
            @headers = row.headers
            strata_headers = @headers[4..]

            errors = process_row(row, strata_headers, stratified_sortition, sample_import)

            processing_errors << errors if errors.present?
          end

          status = processing_errors.flatten.empty? ? :completed : :failed
          sample_import.update(
            status:,
            total_rows:,
            imported_rows: total_rows - processing_errors.flatten.size,
            failed_rows: processing_errors.flatten.size,
            import_errors: processing_errors.flatten
          )

          Decidim::StratifiedSortitions::Admin::ImportMailer.import(user, sample_import).deliver_now
        end

        private

        def process_row(row, _strata_headers, stratified_sortition, sample_import)
          ActiveRecord::Base.transaction do
            participant = Decidim::StratifiedSortitions::SampleParticipant.find_or_create_by(
              personal_data_1: row[0]
            )

            participant.update!(
              decidim_stratified_sortition: stratified_sortition,
              decidim_stratified_sortitions_sample_import: sample_import,
              personal_data_2: row[1],
              personal_data_3: row[2],
              personal_data_4: row[3],
            )

            # Strata is saved in the order of the strata creation
            strata = Decidim::StratifiedSortitions::Stratum.where(stratified_sortition:).order(position: :asc)

            strata_index = 4
            strata.each do |stratum|
              row_value = row[strata_index]

              substratum = find_substratum(stratum, row_value)

              raise "No valid substratum found for value '#{row_value}' in stratum '#{stratum.name}'" if substratum.nil?

              Decidim::StratifiedSortitions::SampleParticipantStratum.create!(
                decidim_stratified_sortitions_sample_participant: participant,
                decidim_stratified_sortitions_stratum: stratum,
                decidim_stratified_sortitions_substratum: substratum
              )

              strata_index += 1
            end
          end

          nil
        rescue StandardError => e
          {
            row: row.to_h,
            error: e.message,
            backtrace: e.backtrace.first(3),
          }
        end

        def find_substratum(stratum, value)
          if stratum.kind == "value"
            Decidim::StratifiedSortitions::Substratum.find_by(
              decidim_stratified_sortitions_stratum_id: stratum.id,
              value:
            )
          elsif stratum.kind == "numeric_range"
            numeric_value = value.to_f
            stratum.substrata.find do |substratum|
              next if substratum.range.blank?

              range_parts = substratum.range.split("-")
              min_value = range_parts[0].to_f
              max_value = range_parts[1].to_f

              numeric_value >= min_value && numeric_value <= max_value
            end
          end
        end
      end
    end
  end
end
