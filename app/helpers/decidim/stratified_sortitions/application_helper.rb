# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # Custom helpers, scoped to the stratified_sortitions engine.
    #
    module ApplicationHelper
      def component_name
        i18n_key = "decidim.components.stratified_sortitions.name"
        (defined?(current_component) && translated_attribute(current_component&.name).presence) || t(i18n_key)
      end

      def filter_custom_state_values
        Decidim::CheckBoxesTreeHelper::TreeNode.new(
          Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.stratified_sortitions.stratified_sortitions_helper.filter_state_values.all")),
          [
            Decidim::CheckBoxesTreeHelper::TreePoint.new("proposal", t("decidim.stratified_sortitions.stratified_sortitions_helper.filter_state_values.proposal")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("execution", t("decidim.stratified_sortitions.stratified_sortitions_helper.filter_state_values.execution")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("finished", t("decidim.stratified_sortitions.stratified_sortitions_helper.filter_state_values.finished")),
          ]
        )
      end
    end
  end
end
