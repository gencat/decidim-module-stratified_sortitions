# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # Custom helpers, scoped to the stratified sortitions engine.
    #
    module StratifiedSortitionsHelper
      def filter_sections
        items = []
        items.append(method: :with_any_state, collection: filter_custom_state_values, label_scope: "decidim.shared.filters", id: "state")
        items.append(method: :related_to, collection: linked_classes_filter_values_for(Decidim::StratifiedSortitions::StratifiedSortition), label_scope: "decidim.shared.filters", id: "related_to",
                     type: :radio_buttons)
        if current_participatory_space.has_subscopes?
          items.append(method: :with_any_scope, collection: filter_global_scopes_values, label_scope: "decidim.shared.filters",
                       id: "scope")
        end

        items.reject { |item| item[:collection].blank? }
      end

      def stratified_sortition_associated_solutions(stratified_sortition)
        solutions_component = Decidim::Component.find_by(participatory_space: stratified_sortition.participatory_space, manifest_name: "solutions")
        return [] unless solutions_component&.published?

        problems_component = Decidim::Component.find_by(participatory_space: stratified_sortition.participatory_space, manifest_name: "problems")
        if problems_component&.published?
          stratified_sortition.problems.published.map { |problem| problem.solutions.published }.flatten
        else
          stratified_sortition.solutions.published
        end
      end

      def truncate_description(description)
        translated_description = raw translated_attribute description
        decidim_sanitize(html_truncate(translated_description, length: 200))
      end
    end
  end
end
