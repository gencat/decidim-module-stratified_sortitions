# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # This cell renders the stratified sortition metadata for l card
    class StratifiedSortitionMetadataCell < Decidim::CardMetadataCell
      include Decidim::StratifiedSortitions::ApplicationHelper

      def initialize(*)
        super

        @items.prepend(*stratified_sortition_items)
      end

      def stratified_sortition_items
        [candidates_item, status_item]
      end

      def candidates_item
        {
          text: data_with_text(model.num_candidates.to_s, t("decidim.stratified_sortitions.stratified_sortitions.stratified_sortition.num_candidates")),
          icon: "group-line"
        }
      end

      def status_item
        {
          text: content_tag(:span, class: "label #{status_classes}") { status_name }
        }
      end

      def strata_item
        {
          text: data_with_text(model.strata.count.to_s, t("decidim.stratified_sortitions.stratified_sortitions.stratified_sortition.strata_count")),
          icon: "bar-chart-box-line"
        }
      end

      def has_badge?
        false
      end

      def status_name
        t(model.status, scope: "decidim.stratified_sortitions.stratified_sortitions.show.statuses", default: model.status)
      end

      def data_with_text(data, text)
        "#{content_tag(:strong) { data }}#{content_tag(:span) { text }}".html_safe
      end

      def status_classes
        case model.status
        when "executed"
          "success"
        when "pending"
          "warning"
        else
          "muted"
        end
      end
    end
  end
end
