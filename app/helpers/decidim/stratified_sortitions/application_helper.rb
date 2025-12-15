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

      def tabs_id_for_stratum(stratum)
        "stratified_sortition_stratum_#{stratum.to_param}"
      end
    end
  end
end
