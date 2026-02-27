# frozen_string_literal: true

require "csv"
require "rubyXL"
require "rubyXL/convenience_methods/cell"
require "rubyXL/convenience_methods/font"
require "rubyXL/convenience_methods/workbook"
require "rubyXL/convenience_methods/worksheet"

module Decidim
  module StratifiedSortitions
    # Custom exporter for sortition results that produces a layout with:
    #   Row 1: Metadata headers
    #   Row 2: Metadata values
    #   Row 3: Blank
    #   Row 4: Participant headers
    #   Row 5+: Participant data
    class SortitionResultsExporter
      def initialize(stratified_sortition)
        @stratified_sortition = stratified_sortition
        @portfolio = stratified_sortition.panel_portfolio
        @audit_log = @portfolio.audit_log
        @strata = stratified_sortition.strata.order(:position)
        @participants = SampleParticipant
                          .where(id: @portfolio.selected_panel)
                          .includes(sample_participant_strata: %i[decidim_stratified_sortitions_stratum decidim_stratified_sortitions_substratum])
                          .order(:id)
        @total_participants = stratified_sortition.sample_participants.count
      end

      def export_csv(col_sep = Decidim.default_csv_col_sep)
        data = ::CSV.generate(col_sep:) do |csv|
          csv << metadata_headers
          csv << metadata_values
          csv << [] # blank row
          csv << participant_headers
          @participants.each { |p| csv << participant_row(p) }
        end
        Decidim::Exporters::ExportData.new(data, "csv")
      end

      def export_excel
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Row 0: metadata headers
        metadata_headers.each_with_index do |header, col|
          worksheet.add_cell(0, col, header)
          worksheet.change_column_width(col, 20)
        end
        style_header_row(worksheet, 0, metadata_headers.size)

        # Row 1: metadata values
        metadata_values.each_with_index { |val, col| worksheet.add_cell(1, col, val) }

        # Row 2: blank
        # Row 3: participant headers
        participant_headers.each_with_index do |header, col|
          worksheet.add_cell(3, col, header)
          current_width = worksheet.get_column_width(col)
          worksheet.change_column_width(col, 20) if current_width.nil? || current_width < 20
        end
        style_header_row(worksheet, 3, participant_headers.size)

        # Row 4+: participant data
        @participants.each_with_index do |participant, idx|
          participant_row(participant).each_with_index do |val, col|
            worksheet.add_cell(4 + idx, col, val)
          end
        end

        Decidim::Exporters::ExportData.new(workbook.stream.string, "xlsx")
      end

      def export_json
        data = {
          metadata: metadata_headers.zip(metadata_values).to_h,
          participants: @participants.map do |p|
            participant_headers.zip(participant_row(p)).to_h
          end
        }
        Decidim::Exporters::ExportData.new(JSON.pretty_generate(data), "json")
      end

      private

      def metadata_headers
        @metadata_headers ||= %w[
          algorithm total_participants generated_at generation_time
          num_panels selected_at verification_seed random_value_used
          selected_panel_probability
        ]
      end

      def metadata_values
        @metadata_values ||= [
          "#{@audit_log[:algorithm]} v#{@audit_log[:version]}",
          @total_participants,
          @portfolio.generated_at,
          @portfolio.generation_time_seconds,
          @portfolio.num_panels,
          @portfolio.selected_at,
          @portfolio.verification_seed || "-",
          @portfolio.random_value_used,
          format_percentage(@portfolio.selected_panel_probability),
        ]
      end

      def participant_headers
        @participant_headers ||= begin
          headers = %w[personal_data_1 personal_data_2 personal_data_3 personal_data_4]
          @strata.each do |stratum|
            stratum_name = stratum.name.values.compact.first || stratum.id.to_s
            headers << "stratum_#{stratum_name}"
          end
          headers
        end
      end

      def participant_row(participant)
        row = [
          participant.personal_data_1,
          participant.personal_data_2,
          participant.personal_data_3,
          participant.personal_data_4,
        ]
        @strata.each do |stratum|
          ps = participant.sample_participant_strata.find { |s| s.decidim_stratified_sortitions_stratum_id == stratum.id }
          substratum_name = ps&.decidim_stratified_sortitions_substratum&.name&.values&.compact&.first
          row << (substratum_name || "-")
        end
        row
      end

      def style_header_row(worksheet, row_index, col_count)
        worksheet.change_row_fill(row_index, "c0c0c0")
        worksheet.change_row_bold(row_index, true)
        worksheet.change_row_horizontal_alignment(row_index, "center")
      end

      def format_percentage(value)
        pct = value.to_f * 100
        "#{format("%.2f", pct)}%"
      end
    end
  end
end
