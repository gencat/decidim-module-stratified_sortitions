# frozen_string_literal: true

require "csv"
require "rubyXL"

module Decidim
  module StratifiedSortitions
    module Admin
      class ImportSampleJob < ApplicationJob
        queue_as :stratified_sortitions

        def perform(file_content, filename, stratified_sortition, user)
          sample_import = Decidim::StratifiedSortitions::SampleImport.create!(
            stratified_sortition:,
            filename:,
            status: :processing
          )
          processing_errors = []
          total_rows = 0

          each_import_row(file_content, filename) do |headers, row|
            total_rows += 1

            errors = process_row(row, headers, stratified_sortition, sample_import)

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

        def each_import_row(file_content, filename)
          if File.extname(filename.to_s).casecmp(".xlsx").zero?
            parse_xlsx_rows(file_content) { |headers, row| yield(headers, row) }
          else
            parse_csv_rows(file_content) { |headers, row| yield(headers, row) }
          end
        end

        def parse_csv_rows(file_content)
          CSV.parse(file_content, headers: true, col_sep: ",") do |row|
            headers = row.headers
            values = row.fields.map { |value| normalize_value(value) }
            next if values.all?(&:blank?)

            yield(headers, values)
          end
        end

        def parse_xlsx_rows(file_content)
          workbook = RubyXL::Parser.parse_buffer(file_content)
          worksheet = workbook[0]
          rows = worksheet&.sheet_data&.rows || []
          return if rows.empty?

          headers = extract_xlsx_row_values(rows.first)

          rows.drop(1).each do |xlsx_row|
            values = extract_xlsx_row_values(xlsx_row)
            next if values.all?(&:blank?)

            yield(headers, values)
          end
        end

        def extract_xlsx_row_values(xlsx_row)
          return [] unless xlsx_row&.cells

          last_index = xlsx_row.cells.rindex { |cell| cell&.value.present? }
          return [] unless last_index

          (0..last_index).map do |index|
            normalize_value(xlsx_row.cells[index]&.value)
          end
        end

        def normalize_value(value)
          return nil if value.nil?

          normalized = value.is_a?(String) ? value.strip : value.to_s.strip
          normalized.presence
        end

        def process_row(row, headers, stratified_sortition, sample_import)
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
            row: build_error_row(headers, row),
            error: e.message,
            backtrace: e.backtrace.first(3),
          }
        end

        def build_error_row(headers, row)
          return row if headers.blank?

          headers.each_with_index.to_h do |header, index|
            [header, row[index]]
          end
        end

        def find_substratum(stratum, value)
          if stratum.kind == "value"
            normalized_value = normalize_value(value)
            Decidim::StratifiedSortitions::Substratum.find_by(
              decidim_stratified_sortitions_stratum_id: stratum.id,
              value: normalized_value
            )
          elsif stratum.kind == "numeric_range"
            numeric_value = normalize_value(value).to_f
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
