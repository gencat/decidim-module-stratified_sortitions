# frozen_string_literal: true

require "wicked_pdf"

module Decidim
  module StratifiedSortitions
    # Generates a PDF with comparative pie charts for a stratified sortition.
    # Uses WickedPdf (wkhtmltopdf) to convert an HTML template to PDF
    class ChartsPdfGenerator
      def initialize(stratified_sortition, strata_data, candidates_data, results_data, locale: I18n.locale)
        @stratified_sortition = stratified_sortition
        @strata_data = strata_data
        @candidates_data = candidates_data
        @results_data = results_data
        @locale = locale
      end

      def generate
        I18n.with_locale(@locale) do
          html = controller.render_to_string(
            template: "decidim/stratified_sortitions/admin/stratified_sortitions/export_charts_pdf",
            layout: "decidim/stratified_sortitions/charts_pdf",
            assigns: template_assigns
          )

          WickedPdf.new.pdf_from_string(html, orientation: "Portrait", page_size: "A4")
        end
      end

      private

      def template_assigns
        {
          title: t("pdf_title", name: translated_name(@stratified_sortition.title)),
          subtitle: t("pdf_subtitle"),
          belongs_to: t("pdf_belongs_to", space_name: participatory_space_name),
          algorithm: t("pdf_algorithm", algorithm: algorithm_info),
          executed_at: t("pdf_executed_at", date: execution_date),
          no_data_text: t("pdf_no_data"),
          col_target: t("target"),
          col_candidates: t("candidates"),
          col_results: t("results"),
          strata_chart_data: build_strata_chart_data
        }
      end

      def build_strata_chart_data
        @strata_data.each_with_index.map do |sd, idx|
          {
            name: translated_name(sd[:stratum].name),
            target: sd[:chart_data],
            candidates: @candidates_data[idx][:chart_data],
            results: @results_data[idx][:chart_data]
          }
        end
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

      def controller
        @controller ||= ChartsPdfControllerHelper.new
      end
    end
  end
end
