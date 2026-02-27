# frozen_string_literal: true

require "prawn"
require "prawn/table"

module Decidim
  module StratifiedSortitions
    # Generates a PDF with comparative pie charts for a stratified sortition.
    # Portrait A4 layout, compact to fit on a single page when possible.
    #
    # Layout:
    #   - Title + subtitle + metadata
    #   - For each stratum: 3 pie charts side by side (target, candidates, results) with legend
    class ChartsPdfGenerator
      COLORS = %w[
        3366CC DC3912 FF9900 109618 990099
        0099C6 DD4477 66AA00 B82E2E 316395
        994499 22AA99 AAAA11 6633CC E67300
        8B0707 651067 329262 5574A6 3B3EAC
      ].freeze

      HEADER_HEIGHT = 80 # approximate height for title + subtitle + info + rule
      MIN_PIE_RADIUS = 22
      MAX_PIE_RADIUS = 48
      LEGEND_ITEM_HEIGHT = 11
      LEGEND_BOX_SIZE = 8
      COL_GAP = 12

      def initialize(stratified_sortition, strata_data, candidates_data, results_data, locale: I18n.locale)
        @stratified_sortition = stratified_sortition
        @strata_data = strata_data
        @candidates_data = candidates_data
        @results_data = results_data
        @locale = locale
      end

      def generate
        I18n.with_locale(@locale) do
          build_pdf
        end
      end

      private

      def build_pdf
        pdf = Prawn::Document.new(page_size: "A4", page_layout: :portrait, margin: [25, 30, 25, 30])

        compute_layout(pdf)
        draw_header(pdf)
        draw_info(pdf)
        pdf.move_down 8

        strata_names = @strata_data.map { |sd| translated_name(sd[:stratum].name) }

        draw_column_headers(pdf)

        strata_names.each_with_index do |stratum_name, idx|
          target_data = @strata_data[idx][:chart_data]
          candidates = @candidates_data[idx][:chart_data]
          results = @results_data[idx][:chart_data]

          space_needed = estimate_stratum_height(target_data, candidates, results)
          if pdf.cursor < space_needed
            pdf.start_new_page
            draw_column_headers(pdf)
          end

          draw_stratum_section(pdf, stratum_name, target_data, candidates, results)
          pdf.move_down @stratum_gap
        end

        pdf.render
      end

      # Compute dynamic sizing so all strata fit on one page when possible.
      def compute_layout(pdf)
        page_height = pdf.bounds.height
        available = page_height - HEADER_HEIGHT
        num_strata = @strata_data.size

        max_legend_items = [@strata_data, @candidates_data, @results_data].flatten.map { |d| d[:chart_data]&.size || 0 }.max
        max_legend_items = [max_legend_items, 1].max

        # Target height per stratum: divide available space
        target_per_stratum = available / [num_strata, 1].max

        # Stratum overhead: title(14) + col_headers(12) + spacing(6+6+4) = ~42
        stratum_overhead = 42
        legend_height = (max_legend_items * LEGEND_ITEM_HEIGHT) + 4
        # Available for pie diameter
        available_for_pie = target_per_stratum - stratum_overhead - legend_height
        ideal_radius = (available_for_pie / 2.0).clamp(MIN_PIE_RADIUS, MAX_PIE_RADIUS)

        @pie_radius = ideal_radius
        @col_width = (pdf.bounds.width - (COL_GAP * 2)) / 3.0
        @stratum_gap = [4, (target_per_stratum * 0.04)].max.clamp(4, 12)
      end

      def draw_header(pdf)
        sortition_name = translated_name(@stratified_sortition.title)
        title = t("pdf_title", name: sortition_name)
        subtitle = t("pdf_subtitle")

        pdf.text title, size: 14, style: :bold, align: :center
        pdf.move_down 2
        pdf.text subtitle, size: 9, style: :italic, align: :center, color: "555555"
        pdf.move_down 6
        pdf.stroke_horizontal_rule
        pdf.move_down 6
      end

      def draw_info(pdf)
        space_name = participatory_space_name
        algorithm = algorithm_info
        executed_at = execution_date

        pdf.text t("pdf_belongs_to", space_name: space_name), size: 8
        pdf.text t("pdf_algorithm", algorithm: algorithm), size: 8
        pdf.text t("pdf_executed_at", date: executed_at), size: 8
        pdf.move_down 30
      end

      def draw_column_headers(pdf)
        start_x = 0
        column_headers = [t("target"), t("candidates"), t("results")]
        header_size = 9
        top = pdf.cursor
        3.times do |i|
          x = start_x + (i * (@col_width + COL_GAP))
          label = column_headers[i]
          label_w = pdf.width_of(label, size: header_size)
          pdf.draw_text label, at: [x + (@col_width / 2.0) - (label_w / 2.0), top], size: header_size, style: :bold
        end
        # Vertical separators before 2nd and 3rd columns
        draw_column_separators(pdf, top + 12, top - 4)
        pdf.move_down 14
      end

      def draw_stratum_section(pdf, stratum_name, target_data, candidates_data, results_data)
        pdf.text stratum_name.upcase, size: 10, style: :bold, color: "333333"
        pdf.move_down 4

        start_x = 0
        chart_top = pdf.cursor

        datasets = [target_data, candidates_data, results_data]

        pie_cy = chart_top - @pie_radius

        3.times do |i|
          x_center = start_x + (i * (@col_width + COL_GAP)) + (@col_width / 2.0)
          data = datasets[i]

          if data.present?
            draw_pie_chart(pdf, x_center, pie_cy, @pie_radius, data)
            legend_y = pie_cy - @pie_radius - 6
            legend_x = start_x + (i * (@col_width + COL_GAP))
            draw_legend(pdf, legend_x, legend_y, @col_width, data)
          else
            pdf.draw_text t("pdf_no_data"), at: [x_center - 20, pie_cy], size: 8, color: "999999"
          end
        end

        legend_items = datasets.map { |d| d.present? ? d.size : 1 }.max
        legend_h = (legend_items * LEGEND_ITEM_HEIGHT) + 4
        total_drop = (@pie_radius * 2) + 6 + legend_h
        new_cursor = chart_top - total_drop

        # Vertical separators for this stratum row
        draw_column_separators(pdf, chart_top + 2, new_cursor)

        pdf.move_cursor_to [new_cursor, 0].max
      end

      # Draws light vertical lines before the 2nd and 3rd columns
      def draw_column_separators(pdf, y_top, y_bottom)
        pdf.save_graphics_state do
          pdf.stroke_color "CCCCCC"
          pdf.line_width = 0.5
          [1, 2].each do |i|
            sep_x = (i * (@col_width + COL_GAP)) - (COL_GAP / 2.0)
            pdf.stroke_line [sep_x, y_top], [sep_x, y_bottom]
          end
        end
      end

      def draw_pie_chart(pdf, cx, cy, radius, data)
        total = data.sum { |_label, value| value.to_f }
        return if total.zero?

        start_angle = 0

        data.each_with_index do |(_label, value), idx|
          slice_angle = (value.to_f / total) * 360.0
          color = COLORS[idx % COLORS.size]
          draw_pie_slice(pdf, cx, cy, radius, start_angle, start_angle + slice_angle, color)
          start_angle += slice_angle
        end

        # White border circle for clean look
        pdf.stroke_color "FFFFFF"
        pdf.line_width = 0.5
        pdf.stroke_circle [cx, cy], radius
        pdf.stroke_color "000000"
        pdf.line_width = 1
      end

      def draw_pie_slice(pdf, cx, cy, radius, start_deg, end_deg, color)
        return if (end_deg - start_deg).abs < 0.01

        pdf.fill_color color
        pdf.stroke_color "FFFFFF"
        pdf.line_width = 0.5

        points = [[cx, cy]]
        step = 2.0
        angle = start_deg
        while angle <= end_deg
          rad = angle * Math::PI / 180.0
          points << [cx + (radius * Math.cos(rad)), cy + (radius * Math.sin(rad))]
          angle += step
        end
        rad = end_deg * Math::PI / 180.0
        points << [cx + (radius * Math.cos(rad)), cy + (radius * Math.sin(rad))]
        points << [cx, cy]

        pdf.fill_and_stroke do
          pdf.move_to(*points.first)
          points[1..].each { |pt| pdf.line_to(*pt) }
          pdf.close_path
        end

        pdf.fill_color "000000"
        pdf.stroke_color "000000"
      end

      def draw_legend(pdf, x, y, col_width, data)
        total = data.sum { |_label, value| value.to_f }

        # Calculate max legend item width to center the block
        legend_texts = data.map do |(label, value)|
          percentage = total.positive? ? ((value.to_f / total) * 100).round(1) : 0.0
          "#{label} (#{percentage}%)"
        end
        max_text_w = legend_texts.map { |txt| pdf.width_of(txt, size: 7) }.max || 0
        block_width = LEGEND_BOX_SIZE + 3 + max_text_w
        offset_x = x + ((col_width - block_width) / 2.0)

        current_y = y

        data.each_with_index do |(label, value), idx|
          color = COLORS[idx % COLORS.size]
          percentage = total.positive? ? ((value.to_f / total) * 100).round(1) : 0.0

          pdf.fill_color color
          pdf.fill_rectangle [offset_x, current_y], LEGEND_BOX_SIZE, LEGEND_BOX_SIZE
          pdf.fill_color "000000"

          legend_text = "#{label} (#{percentage}%)"
          pdf.draw_text legend_text, at: [offset_x + LEGEND_BOX_SIZE + 3, current_y - (LEGEND_BOX_SIZE - 1)], size: 7

          current_y -= LEGEND_ITEM_HEIGHT
        end
      end

      def estimate_stratum_height(target_data, candidates_data, results_data)
        max_items = [
          target_data&.size || 0,
          candidates_data&.size || 0,
          results_data&.size || 0,
        ].max
        legend_height = (max_items * LEGEND_ITEM_HEIGHT) + 4
        # title(14) + gap(4) + pie_diameter + gap(6) + legend + margin
        14 + 4 + (@pie_radius * 2) + 6 + legend_height + 10
      end

      def translated_name(hash)
        return hash if hash.is_a?(String)

        hash[@locale.to_s] || hash[hash.keys.first] || ""
      end

      def participatory_space_name
        space = @stratified_sortition.participatory_space
        translated_name(space.title)
      rescue StandardError
        "-"
      end

      def algorithm_info
        portfolio = @stratified_sortition.panel_portfolio
        return "-" unless portfolio&.sampled?

        "#{portfolio.audit_log[:algorithm]} v#{portfolio.audit_log[:version]}"
      end

      def execution_date
        portfolio = @stratified_sortition.panel_portfolio
        return "-" unless portfolio&.sampled?

        I18n.l(portfolio.selected_at, format: :decidim_short)
      rescue StandardError
        portfolio.selected_at.to_s
      end

      def t(key, **opts)
        I18n.t(key, scope: "decidim.stratified_sortitions.admin.stratified_sortitions.execute", **opts)
      end
    end
  end
end
