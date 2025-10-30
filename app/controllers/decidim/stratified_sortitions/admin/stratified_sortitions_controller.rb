# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Controller that allows managing admin stratified sortitions.
      #
      class StratifiedSortitionsController < Decidim::StratifiedSortitions::Admin::ApplicationController
        include Decidim::ApplicationHelper

        helper StratifiedSortitions::ApplicationHelper
        helper Decidim::Sdgs::SdgsHelper
        helper Decidim::PaginateHelper

        helper_method :stratified_sortitions, :stratified_sortition, :form_presenter

        def index
          enforce_permission_to :read, :stratified_sortitions
          @stratified_sortitions = stratified_sortitions
        end

        def new
          enforce_permission_to :create, :stratified_sortition
          @form = form(Decidim::StratifiedSortitions::Admin::StratifiedSortitionsForm).instance
        end

        def edit
          enforce_permission_to(:edit, :stratified_sortition, stratified_sortition:)
          @form = form(Decidim::StratifiedSortitions::Admin::StratifiedSortitionsForm).from_model(stratified_sortition)
        end

        def create
          enforce_permission_to :create, :stratified_sortition
          @form = form(Decidim::StratifiedSortitions::Admin::StratifiedSortitionsForm).from_params(params)

          Decidim::StratifiedSortitions::Admin::CreateStratifiedSortition.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("stratified_sortitions.create.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to stratified_sortitions_path(assembly_slug: -1, component_id: -1)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("stratified_sortitions.create.error", scope: "decidim.stratified_sortitions.admin")
              render action: "new"
            end
          end
        end

        def update
          enforce_permission_to(:edit, :stratified_sortition, stratified_sortition:)
          @form = form(Decidim::StratifiedSortitions::Admin::StratifiedSortitionsForm).from_params(params)

          Decidim::StratifiedSortitions::Admin::UpdateStratifiedSortition.call(@form, stratified_sortition) do
            on(:ok) do |_stratified_sortition|
              flash[:notice] = t("stratified_sortitions.update.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to stratified_sortitions_path(assembly_slug: -1, component_id: -1)
            end

            on(:invalid) do
              flash.now[:alert] = t("stratified_sortitions.update.error", scope: "decidim.stratified_sortitions.admin")
              render :edit
            end
          end
        end

        def destroy
          enforce_permission_to(:destroy, :stratified_sortition, stratified_sortition:)

          Decidim::StratifiedSortitions::Admin::DestroyStratifiedSortition.call(stratified_sortition, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("stratified_sortitions.destroy.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to stratified_sortitions_path(assembly_slug: -1, component_id: -1)
            end

            on(:has_problems) do
              redirect_to stratified_sortitions_path, flash: { error: t("stratified_sortitions.destroy.has_problems", scope: "decidim.stratified_sortitions.admin") }
            end

            on(:invalid) do
              redirect_to stratified_sortitions_path, flash: { error: t("stratified_sortitions.destroy.error", scope: "decidim.stratified_sortitions.admin") }
            end
          end
        end

        private

        def collection
          @collection ||= StratifiedSortition.where(component: current_component)
        end

        def stratified_sortitions
          @stratified_sortitions ||= collection.page(params[:page]).per(10)
        end

        def stratified_sortition
          @stratified_sortition ||= collection.find(params[:id])
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::StratifiedSortitions::StratifiedSortitionPresenter)
        end
      end
    end
  end
end
