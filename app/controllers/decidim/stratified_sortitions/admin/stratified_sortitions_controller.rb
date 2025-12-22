# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Controller that allows managing admin stratified sortitions.
      #
      class StratifiedSortitionsController < Decidim::StratifiedSortitions::Admin::ApplicationController
        include Decidim::ApplicationHelper

        helper StratifiedSortitions::ApplicationHelper
        helper Decidim::PaginateHelper

        helper_method :stratified_sortitions, :stratified_sortition, :form_presenter, :blank_stratum, :blank_substratum

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

        def duplicate
          enforce_permission_to(:duplicate, :stratified_sortition, stratified_sortition:)

          Decidim::StratifiedSortitions::Admin::DuplicateStratifiedSortition.call(stratified_sortition, current_user) do
            on(:ok) do |_new_stratified_sortition|
              flash[:notice] = I18n.t("stratified_sortitions.duplicate.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to stratified_sortitions_path(assembly_slug: -1, component_id: -1)
            end

            on(:invalid) do
              flash[:alert] = I18n.t("stratified_sortitions.duplicate.error", scope: "decidim.stratified_sortitions.admin")
              redirect_to stratified_sortitions_path(assembly_slug: -1, component_id: -1)
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

        def upload_sample
          enforce_permission_to :upload_sample, :stratified_sortition

          # if params[:file]
          #   data = CsvData.new(params[:file].path)
          #   # rubocop: disable Rails/SkipsModelValidations
          #   CensusDatum.insert_all(current_organization, data.values, data.headers[2..])
          #   # rubocop: enable Rails/SkipsModelValidations
          #   RemoveDuplicatesJob.perform_later(current_organization)
          #   flash[:notice] = t(".success", count: data.values.count,
          #                                  errors: data.errors.count)
          #   redirect_to censuses_path
          # end
          @stratified_sortition = stratified_sortition
          @filenames = [["01/04/2025", 567], ["15/05/2024", 123]]
        end

        def process_sample
                    
          force_permission_to :upload_sample, :stratified_sortition

          unless params[:file].present?
            flash[:alert] = t("decidim.stratified_sortitions.admin.samples.errors.no_file")
            redirect_back(fallback_location: stratified_sortitions_path) and return
          end

          # Save uploaded file to a temp location
          uploaded_file = params[:file]
          tmp_path = Rails.root.join("tmp", "sample_import_#{SecureRandom.hex(8)}.csv")
          File.open(tmp_path, 'wb') { |f| f.write(uploaded_file.read) }

          # Create SampleImport record
          sample_import = SampleImport.create!(
            stratified_sortition: stratified_sortition,
            filename: uploaded_file.original_filename,
            status: :pending
          )

          # Run import (ideally in background job, here sync for simplicity)
          begin
            SampleImportService.new(
              file_path: tmp_path,
              stratified_sortition: stratified_sortition,
              sample_import: sample_import
            ).run
            flash[:notice] = t("decidim.stratified_sortitions.admin.samples.import_success")
          rescue => e
            flash[:alert] = t("decidim.stratified_sortitions.admin.samples.import_failed", error: e.message)
          ensure
            File.delete(tmp_path) if File.exist?(tmp_path)
          end
          redirect_to stratified_sortition_path(stratified_sortition)
          # redirect_to upload_sample_stratified_sortition_path(stratified_sortition)
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
