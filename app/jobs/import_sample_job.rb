# frozen_string_literal: true

require "csv"

class ImportSampleJob < ApplicationJob
  queue_as :default

  # Expects a file as argument
  def perform(file, stratified_sortition)
    byebug
    sample_import = Decidim::StratifiedSortitions::SampleImport.create!(
      stratified_sortition:,
      filename: File.basename(file),
      status: :processing
    )

    CSV.foreach(file, headers: true, col_sep: ",") do |row|
      @headers = row.headers
      strata_headers = @headers[4..]

      process_row(row, strata_headers, stratified_sortition, sample_import)

      # participant_attrs = row.to_h

      # participant = Participant.find_or_create_by(email: participant_attrs[:email]) do |p|
      #   p.name = participant_attrs[:name]
      #   p.other_attributes = participant_attrs[:other_attributes]
      # end

      # stratum = Stratum.find_or_create_by(name: participant_attrs[:stratum_name])
      # substratum = Substratum.find_or_create_by(name: participant_attrs[:substratum_name], stratum: stratum)
      # ParticipantSubstratum.find_or_create_by(participant: participant, substratum: substratum)
    end
  end

  private

  def process_row(row, strata_headers, stratified_sortition, sample_import)
   participant = Decidim::StratifiedSortitions::SampleParticipant.create!(
      decidim_stratified_sortition: stratified_sortition,
      sample_import:,
      personal_data_1: row[0],
      personal_data_2: row[1],
      personal_data_3: row[2],
      personal_data_4: row[3]
    )

    strata_headers.find_each_with_index do |index, strata|
      Decidim::StratifiedSortitions::SampleParticipantStratum.create!(
        sample_participant: participant,
        stratum: Decidim::StratifiedSortitions::Stratum.find_by(name: strata),
        substratum: Decidim::StratifiedSortitions::Substratum.find_by(name: row[index])
      )
    end
  end
end
