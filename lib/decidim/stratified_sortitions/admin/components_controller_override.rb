# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      module ComponentsControllerOverride
        def index
          super
          @manifests = ComponentVisibility.filter_manifests_for_user(@manifests, current_user)
          @components = ComponentVisibility.filter_components_for_user(@components, current_user)
        end

        def new
          ensure_stratified_sortitions_manifest_allowed!
          super
        end

        def create
          ensure_stratified_sortitions_manifest_allowed!
          super
        end

        def edit
          ensure_stratified_sortitions_component_allowed!
          super
        end

        def update
          ensure_stratified_sortitions_component_allowed!
          super
        end

        def destroy
          ensure_stratified_sortitions_component_allowed!
          super
        end

        def publish
          ensure_stratified_sortitions_component_allowed!
          super
        end

        def unpublish
          ensure_stratified_sortitions_component_allowed!
          super
        end

        def share
          ensure_stratified_sortitions_component_allowed!
          super
        end

        private

        def ensure_stratified_sortitions_manifest_allowed!
          return unless params[:type].to_s == ComponentVisibility::MANIFEST_NAME
          return if ComponentVisibility.allowed_for_user?(current_user)

          raise ActionController::RoutingError, "Not Found"
        end

        def ensure_stratified_sortitions_component_allowed!
          component = query_scope.find_by(id: params[:id])
          return unless component
          return if ComponentVisibility.visible_component?(component, current_user)

          raise ActionController::RoutingError, "Not Found"
        end
      end
    end
  end
end
