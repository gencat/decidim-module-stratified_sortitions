require 'csv'

class SampleImportService
  BATCH_SIZE = 2000

  def initialize(file_path:, stratified_sortition:, sample_import:)
    @file_path = file_path
    @stratified_sortition = stratified_sortition
    @sample_import = sample_import
    @strata = stratified_sortition.strata.order(:position).to_a
    raise "No strata configured" if @strata.empty?
  end

  def run
    @sample_import.update!(status: "processing")
    total = 0
    imported = 0
    failed = 0
    participants_batch = []
    strata_rows_batch = []

    CSV.foreach(@file_path, headers: false, encoding: "utf-8") do |row|
      total += 1
      personal_id = row[0].to_s.strip
      p1 = row[1].to_s.strip.presence
      p2 = row[2].to_s.strip.presence
      p3 = row[3].to_s.strip.presence
      column_values = row.to_a[4..-1] || []
      unless personal_id.present?
        failed += 1
        record_error(total, "Missing personal identifier")
        next
      end
      strata_ok, mapped_substrata = validate_strata_values(column_values)
      unless strata_ok
        failed += 1
        record_error(total, "Strata validation failed")
        next
      end
      participants_batch << SampleParticipant.new(
        stratified_sortition: @stratified_sortition,
        sample_import: @sample_import,
        personal_identifier: personal_id,
        personal_field_1: p1,
        personal_field_2: p2,
        personal_field_3: p3,
        column_values: column_values
      )
      strata_rows_batch << mapped_substrata
      if participants_batch.size >= BATCH_SIZE
        imported += flush_batch!(participants_batch, strata_rows_batch)
        participants_batch.clear
        strata_rows_batch.clear
        broadcast_progress(total, imported, failed)
      end
    end
    imported += flush_batch!(participants_batch, strata_rows_batch) if participants_batch.any?
    @sample_import.update!(total_rows: total, imported_rows: imported, failed_rows: failed, status: "completed")
    broadcast_progress(total, imported, failed, finished: true)
  rescue => e
    @sample_import.update!(status: "failed", errors: { message: e.message })
    raise e
  end

  private

  def validate_strata_values(column_values)
    mapped = []
    @strata.each_with_index do |stratum, idx|
      value = column_values[idx]
      substratum = find_matching_substratum(stratum, value)
      mapped << { stratum_id: stratum.id, substratum_id: substratum&.id, raw_value: value }
    end
    [true, mapped]
  end

  def find_matching_substratum(stratum, value)
    stratum.substrata.find { |s| s.matches_value?(value) } # implement matches_value? in model
  end

  def flush_batch!(participants_batch, strata_rows_batch)
    SampleParticipant.import participants_batch, validate: false
    persisted_ids = SampleParticipant.where(stratified_sortition: @stratified_sortition).order(:created_at).pluck(:id).last(participants_batch.size)
    rows = []
    persisted_ids.each_with_index do |pid, i|
      strata_rows_batch[i].each do |map|
        rows << SampleParticipantStratum.new(
          sample_participant_id: pid,
          stratum_id: map[:stratum_id],
          substratum_id: map[:substratum_id],
          raw_value: map[:raw_value]
        )
      end
    end
    SampleParticipantStratum.import rows, validate: false
    participants_batch.size
  end

  def record_error(row_number, message)
    (@sample_import.errors ||= []) << { row: row_number, error: message }
  end

  def broadcast_progress(total, imported, failed, finished: false)
    ActionCable.server.broadcast("sample_import_progress_#{@sample_import.id}", {
      total: total,
      imported: imported,
      failed: failed,
      finished: finished
    })
  end
end
