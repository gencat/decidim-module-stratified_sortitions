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
        "stratified-sortition-stratum-#{stratum.to_param}"
      end

      def tabs_id_for_substratum(substratum)
        "stratified-sortition-stratum-substratum-#{substratum.to_param}"
      end

      # Renders the errors for a given object field in an HTML block.
      # If there are no errors renders nothing.
      def field_errors_block(form, field)
        return if form.object.errors[field].blank?

        html = <<~EOHTML
          <div class="row column errors">#{form.error_for(field)}</div>
        EOHTML
        html.html_safe
      end

      def dynamic_title(title, **options)
        data = {
          "max-length" => options[:max_length],
          "omission" => options[:omission],
          "placeholder" => options[:placeholder],
          "locale" => I18n.locale,
        }
        tag.span(class: options[:class], data:) do
          truncate translated_attribute(title), length: options[:max_length], omission: options[:omission]
        end
      end

      def navigation_menu_items(sortition)
        has_sortition = sortition.present?

        [
          {
            path: has_sortition ? edit_stratified_sortition_path(sortition) : new_stratified_sortition_path,
            icon: "settings-4-line",
            label: t("actions.configure", scope: "decidim.stratified_sortitions.admin"),
            active: %w(new edit).include?(action_name),
          },
          {
            path: has_sortition ? upload_sample_stratified_sortition_path(sortition) : "#",
            icon: "group-line",
            label: t("actions.census_management", scope: "decidim.stratified_sortitions.admin"),
            active: action_name == "upload_sample",
            disabled: has_sortition ? !sortition.strata_and_substrata_configured? : true,
          },
          {
            path: has_sortition ? execute_stratified_sortition_path(sortition) : "#",
            icon: "play-fill",
            label: t("actions.execute", scope: "decidim.stratified_sortitions.admin"),
            active: action_name == "execute",
            disabled: has_sortition ? !sortition.can_execute? : true,
          }
        ]
      end

      def filter_sections_stratified_sortitions
        sections = [{ method: :with_any_state, collection: filter_state_values, label_scope: "decidim.stratified_sortitions.stratified_sortitions.filters", id: "state" }]
        sections.reject { |item| item[:collection].blank? }
      end

      def filter_state_values
        [
          ["all", t("all", scope: "decidim.stratified_sortitions.stratified_sortitions.filters")],
          ["pending", t("pending", scope: "decidim.stratified_sortitions.stratified_sortitions.filters")],
          ["executed", t("executed", scope: "decidim.stratified_sortitions.stratified_sortitions.filters")],
        ]
      end
    end
  end
end
