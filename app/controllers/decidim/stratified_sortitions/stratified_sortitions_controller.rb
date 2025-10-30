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
      include WithSdgs
      include WithDefaultFilters

      helper Decidim::CheckBoxesTreeHelper
      helper Decidim::Sdgs::SdgsHelper
      helper Decidim::ShowFiltersHelper
      helper Decidim::StratifiedSortitions::StratifiedSortitionsHelper
      helper Decidim::PaginateHelper

      helper_method :stratified_sortitions, :has_sdgs?, :new_solution_path, :solutions_component, :default_filter_scope_params

      def index
        @stratified_sortitions = search.result
        @stratified_sortitions = reorder(@stratified_sortitions)
        @stratified_sortitions = paginate(@stratified_sortitions)
      end

      def show
        @stratified_sortition = StratifiedSortition.find(params[:id])
        @stratified_sortition_scope = stratified_sortition_scope
        @sdg = @stratified_sortition.sdg_code if @stratified_sortition.sdg_code.present?
        @sdg_index = (1 + Decidim::Sdgs::Sdg.index_from_code(@stratified_sortition.sdg_code.to_sym)).to_s.rjust(2, "0") if @sdg
      end

      private

      def stratified_sortition_scope
        @stratified_sortition_scope ||= current_organization.scopes.find_by(id: @stratified_sortition.decidim_scope_id)
      end

      def stratified_sortitions
        @stratified_sortitions ||= reorder(paginate(search.result))
      end

      def search_collection
        ::Decidim::StratifiedSortitions::StratifiedSortition.where(component: current_component).published
      end

      def default_filter_params
        {
          search_text_cont: "",
          with_any_state: %w(execution finished),
          with_any_scope: default_filter_scope_params,
          with_any_sdgs_codes: [],
          related_to: "",
        }
      end

      def new_solution_path
        component = solutions_component
        Decidim::EngineRouter.main_proxy(component).new_solution_path
      end

      def solutions_component
        current_participatory_space.components.find_by(manifest_name: "solutions")
      end
    end
  end
end
