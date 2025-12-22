# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Controller that allows managing samples for stratified sortitions.
      #
      class SamplesController < Decidim::StratifiedSortitions::Admin::ApplicationController
        before_action :ensure_strata_configured, only: [:upload_sample, :process_sample]
        before_action :ensure_not_drawn, only: [:upload_sample, :process_sample, :destroy]

        include Decidim::ApplicationHelper

        helper StratifiedSortitions::ApplicationHelper
        helper Decidim::PaginateHelper

        helper_method :stratified_sortitions, :stratified_sortition, :form_presenter, :blank_stratum, :blank_substratum

        def create
          enforce_permission_to :upload_sample, :stratified_sortition
          
          Decidim::StratifiedSortitions::Admin::ImportSample.call(params[:file], stratified_sortition) do
            on(:ok) do
              flash[:notice] = I18n.t("sample_imports.create.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("sample_imports.create.invalid", scope: "decidim.stratified_sortitions.admin")
              render action: "new"
            end
          end
        end


          # if params[:file]
          #   data = CsvData.new(params[:file].path)
          #   # rubocop: disable Rails/SkipsModelValidations
          #   CensusDatum.insert_all(current_organization, data.values, data.headers[2..])
          #   # rubocop: enable Rails/SkipsModelValidations
          #   # RemoveDuplicatesJob.perform_later(current_organization)
          #   flash[:notice] = t(".success", count: data.values.count,
          #                                  errors: data.errors.count)
          # end
          # redirect_to censuses_path
          # 

          
          # Save uploaded file to a temp location
          # uploaded_file = params[:file]
          # tmp_path = Rails.root.join("tmp", "sample_import_#{SecureRandom.hex(8)}.csv")
          # File.open(tmp_path, 'wb') { |f| f.write(uploaded_file.read) }

          # # Create SampleImport record
          # byebug
          # sample_import = Decidim::StratifiedSortitions::SampleImport.create!(
          #   stratified_sortition: stratified_sortition,
          #   filename: uploaded_file.original_filename,
          #   status: :pending
          # )

          # # Run import (ideally in background job, here sync for simplicity)
          # begin
          #   SampleImportService.new(
          #     file_path: tmp_path,
          #     stratified_sortition: stratified_sortition,
          #     sample_import: sample_import
          #   ).run
          #   flash[:notice] = t("decidim.stratified_sortitions.admin.samples.import_success")
          # rescue => e
          #   flash[:alert] = t("decidim.stratified_sortitions.admin.samples.import_failed", error: e.message)
          # ensure
          #   File.delete(tmp_path) if File.exist?(tmp_path)
          # end
          # redirect_to stratified_sortition_path(stratified_sortition)
        # end

        private

        # Business rule: Block import if no strata or substrata configured
        def ensure_strata_configured
          unless stratified_sortition.strata.any? && stratified_sortition.strata.all? { |s| s.substrata.any? }
            flash[:alert] = t("decidim.stratified_sortitions.admin.samples.errors.no_strata")
            redirect_back(fallback_location: stratified_sortitions_path) and return
          end
        end

        # Business rule: Prevent deletion or import if draw is done
        def ensure_not_drawn
          if stratified_sortition.respond_to?(:drawn?) && stratified_sortition.drawn?
            flash[:alert] = t("decidim.stratified_sortitions.admin.samples.errors.drawn")
            redirect_back(fallback_location: stratified_sortitions_path) and return
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
      end
    end
  end
end
