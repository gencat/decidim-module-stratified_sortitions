# frozen_string_literal: true

require "csv"

class ImportSampleJob < ApplicationJob
  queue_as :default

  def perform(file, stratified_sortition, user)
    sample_import = Decidim::StratifiedSortitions::SampleImport.create!(
      stratified_sortition:,
      filename: file.original_filename,
      status: :processing
    )
    processing_errors = []
    total_rows = 0

    CSV.foreach(file, headers: true, col_sep: ",") do |row|
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

  def process_row(row, strata_headers, stratified_sortition, sample_import)
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

    strata_headers.each_with_index do |strata, _index|
      strata_id = strata.split("_").last
      Decidim::StratifiedSortitions::SampleParticipantStratum.create!(
        decidim_stratified_sortitions_sample_participant: participant,
        decidim_stratified_sortitions_stratum: Decidim::StratifiedSortitions::Stratum.find(strata_id),
        decidim_stratified_sortitions_substratum: Decidim::StratifiedSortitions::Substratum.find_by(value: row[strata])
      )
    end

    nil
  rescue StandardError => e
    {
      row: row.to_h,
      error: e.message,
      backtrace: e.backtrace.first(3),
    }
  end
end
