# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # This controller is the abstract class from which all other controllers of
      # this engine inherit.
      #
      # Note that it inherits from `Decidim::Admin::Components::BaseController`, which
      # override its layout and provide all kinds of useful methods.
      class ApplicationController < Decidim::Admin::Components::BaseController
        before_action :hide_component_unless_allowed!

        def index
          enforce_permission_to :read, :stratified_sortitions
          @stratified_sortitions = stratified_sortitions
        end

        private

        def hide_component_unless_allowed!
          return if Decidim::StratifiedSortitions::ComponentVisibility.allowed_for_user?(current_user)

          raise ActionController::RoutingError, "Not Found"
        end
      end
    end
  end
end
