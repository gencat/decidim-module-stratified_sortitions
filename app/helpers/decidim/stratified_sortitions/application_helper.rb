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
    end
  end
end
