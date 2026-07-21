# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module ParticipatoryProcessHelperOverride
      def process_nav_items(participatory_space)
        components = participatory_space.components.published.or(Decidim::Component.where(id: try(:current_component)))
        components = ComponentVisibility.filter_components_for_user(components, current_user)

        components.map do |component|
          {
            name: decidim_escape_translated(component.name),
            url: main_component_path(component),
            active: is_active_link?(main_component_path(component), :inclusive),
          }
        end
      end
    end
  end
end
