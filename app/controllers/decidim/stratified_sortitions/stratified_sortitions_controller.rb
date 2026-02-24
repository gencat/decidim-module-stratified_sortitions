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
          with_any_state: "all"
        }
      end
    end
  end
end
