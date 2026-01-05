# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Controller that allows managing samples for stratified sortitions.
      #
      class SamplesController < Decidim::StratifiedSortitions::Admin::ApplicationController
        include Decidim::TranslatableAttributes

        before_action :ensure_strata_configured, only: [:create, :remove_multiple]
        before_action :ensure_stratified_sortition_is_pending, only: [:create, :remove_multiple]

        include Decidim::ApplicationHelper

        helper StratifiedSortitions::ApplicationHelper
        helper Decidim::PaginateHelper

        helper_method :stratified_sortitions, :stratified_sortition, :form_presenter, :blank_stratum, :blank_substratum

        def download_template
          csv = generate_template_sample
          send_data csv, filename: "sample_importation_template.csv", type: "text/csv"
        end

        def create
          enforce_permission_to :upload_sample, :stratified_sortition

          Decidim::StratifiedSortitions::Admin::ImportSample.call(params[:file], stratified_sortition, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("sample_imports.create.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("sample_imports.create.invalid", scope: "decidim.stratified_sortitions.admin")
              redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
            end
          end
        end

        def remove_multiple
          enforce_permission_to :upload_sample, :stratified_sortition

          Decidim::StratifiedSortitions::Admin::RemoveUploadedSamples.call(stratified_sortition) do
            on(:ok) do
              flash[:notice] = I18n.t("sample_imports.remove_uploaded_samples.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("sample_imports.remove_uploaded_samples.error", scope: "decidim.stratified_sortitions.admin")
              redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
            end
          end
        end

        private

        def ensure_strata_configured
          unless stratified_sortition.strata_and_substrata_configured?
            flash[:alert] = t("decidim.stratified_sortitions.admin.samples.errors.no_strata")
            redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
          end
        end

        def ensure_stratified_sortition_is_pending
          if stratified_sortition.status != "pending"
            flash[:alert] = t("decidim.stratified_sortitions.admin.samples.errors.pending")
            redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
          end
        end

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

        def blank_stratum
          @blank_stratum ||= Decidim::StratifiedSortitions::Admin::StratumForm.new
        end

        def blank_substratum
          @blank_substratum ||= Decidim::StratifiedSortitions::Admin::SubstratumForm.new
        end

        def generate_template_sample
          personal_headers = [
            I18n.t("decidim.stratified_sortitions.admin.samples.template.personal_data_1"),
            I18n.t("decidim.stratified_sortitions.admin.samples.template.personal_data_2"),
            I18n.t("decidim.stratified_sortitions.admin.samples.template.personal_data_3"),
            I18n.t("decidim.stratified_sortitions.admin.samples.template.personal_data_4"),
          ]
          strata = Decidim::StratifiedSortitions::Stratum.order(:id)
          strata_headers = strata.map do |stratum|
            "#{translated_attribute(stratum.name)}_#{stratum.id}"
          end

          headers = personal_headers + strata_headers
          CSV.generate(col_sep: ",") do |csv|
            csv << headers
          end
        end
      end
    end
  end
end
