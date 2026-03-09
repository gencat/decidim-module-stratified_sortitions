# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # Controller that allows browsing stratified sortitions.
    #
    class StratifiedSortitionsController < Decidim::StratifiedSortitions::ApplicationController
      include Decidim::ApplicationHelper
      include FilterResource
      include Paginable
      include OrderableStratifiedSortitions
      include StrataChartsData

      helper Decidim::CheckBoxesTreeHelper
      helper Decidim::PaginateHelper

      helper_method :stratified_sortitions, :stratified_sortition

      def index
        @stratified_sortitions = search.result
        @stratified_sortitions = reorder(@stratified_sortitions)
        @stratified_sortitions = paginate(@stratified_sortitions)
      end

      def show
        raise ActionController::RoutingError, "Not Found" unless stratified_sortition

        if current_component.settings.publish_sortitions
          @strata_data = strata_data(stratified_sortition) if stratified_sortition.strata_and_substrata_configured?
          @candidates_data = candidates_data(stratified_sortition) if stratified_sortition.can_execute?
          @results_data = results_data(stratified_sortition) if stratified_sortition.panel_portfolio&.sampled?
        end
      end

      private

      def stratified_sortition
        @stratified_sortition ||= search_collection.find_by(id: params[:id])
      end

      def stratified_sortition_scope
        @stratified_sortition_scope ||= current_organization.scopes.find_by(id: stratified_sortition&.decidim_scope_id)
      end

      def stratified_sortitions
        @stratified_sortitions ||= reorder(paginate(search.result))
      end

      def search_collection
        ::Decidim::StratifiedSortitions::StratifiedSortition.where(component: current_component)
      end

      def default_filter_params
        {
          search_text_cont: "",
          with_any_state: "all",
        }
      end
    end
  end
end
