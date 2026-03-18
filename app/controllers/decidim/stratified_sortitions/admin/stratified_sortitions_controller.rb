# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Controller that allows managing admin stratified sortitions.
      #
      class StratifiedSortitionsController < Decidim::StratifiedSortitions::Admin::ApplicationController
        include Decidim::ApplicationHelper
        include StrataChartsData

        helper StratifiedSortitions::ApplicationHelper
        helper Decidim::PaginateHelper

        helper_method :stratified_sortitions, :stratified_sortition, :form_presenter, :blank_stratum

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
            on(:ok) do |created_sortition|
              flash[:notice] = I18n.t("stratified_sortitions.create.success", scope: "decidim.stratified_sortitions.admin")
              redirect_to edit_stratified_sortition_path(created_sortition)
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
              redirect_to edit_stratified_sortition_path(stratified_sortition)
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
          if stratified_sortition.strata_and_substrata_configured?
            @stratified_sortition = stratified_sortition
            @form = SampleUploadForm.new
            @sample_participants_count = @stratified_sortition.sample_participants.count
            @last_sample = SampleImport.where(stratified_sortition: @stratified_sortition).order(created_at: :desc).first
            @samples = SampleImport.where(stratified_sortition: @stratified_sortition).order(created_at: :asc)
            @strata_data = strata_data(@stratified_sortition)
            @candidates_data = candidates_data(@stratified_sortition)
          else
            redirect_to edit_stratified_sortition_path(stratified_sortition),
                        flash: { warning: t("stratified_sortitions.upload_sample.strata_not_configured", scope: "decidim.stratified_sortitions.admin") }
          end
        end

        def execute
          unless stratified_sortition.can_execute?
            redirect_to edit_stratified_sortition_path(stratified_sortition),
                        flash: { warning: t("stratified_sortitions.execute.empty_sample_participants", scope: "decidim.stratified_sortitions.admin") }
            return
          end

          @stratified_sortition = stratified_sortition
          @portfolio = @stratified_sortition.panel_portfolio
          @strata = @stratified_sortition.strata.order(:position)
          @selected_participants = if @portfolio&.sampled?
                                     SampleParticipant
                                       .where(id: @portfolio.selected_panel)
                                       .includes(sample_participant_strata: [:decidim_stratified_sortitions_stratum, :decidim_stratified_sortitions_substratum])
                                       .order(:id)
                                       .to_a
                                   else
                                     []
                                   end
          @strata_data = strata_data(@stratified_sortition)
          @candidates_data = candidates_data(@stratified_sortition)
          @results_data = results_data(@stratified_sortition)
        end

        def execute_stratified_sortition
          @result = FairSortitionService.new(stratified_sortition).call
          if @result.success?
            stratified_sortition.update!(status: "executed")
            Decidim.traceability.perform_action!("execute", stratified_sortition, current_user, visibility: "all")
            flash[:notice] = I18n.t("stratified_sortitions.execute.success", scope: "decidim.stratified_sortitions.admin")
          else
            flash[:error] = @result.error
          end
          redirect_to execute_stratified_sortition_path(stratified_sortition)
        end

        def export_charts_pdf
          portfolio = stratified_sortition.panel_portfolio

          unless portfolio&.sampled?
            flash[:error] = I18n.t("stratified_sortitions.export_results.no_results", scope: "decidim.stratified_sortitions.admin")
            redirect_to execute_stratified_sortition_path(stratified_sortition)
            return
          end

          generator = ChartsPdfGenerator.new(
            stratified_sortition,
            strata_data(stratified_sortition),
            candidates_data(stratified_sortition),
            results_data(stratified_sortition),
            locale: I18n.locale
          )

          filename = "sortition_charts_#{stratified_sortition.id}_#{Time.current.strftime("%Y%m%d_%H%M%S")}.pdf"
          send_data generator.generate,
                    filename:,
                    type: "application/pdf",
                    disposition: "attachment"
        end

        def export_results
          format = params[:format]&.downcase || "csv"
          portfolio = stratified_sortition.panel_portfolio

          unless portfolio&.sampled?
            flash[:error] = I18n.t("stratified_sortitions.export_results.no_results", scope: "decidim.stratified_sortitions.admin")
            redirect_to execute_stratified_sortition_path(stratified_sortition)
            return
          end

          SortitionResultsExportJob.perform_later(current_user, stratified_sortition, format)

          Decidim.traceability.perform_action!("export_results", stratified_sortition, current_user, visibility: "all")
          flash[:notice] = I18n.t("decidim.admin.exports.notice")
          redirect_to execute_stratified_sortition_path(stratified_sortition)
        end

        def log_view_participants
          portfolio = stratified_sortition.panel_portfolio

          unless portfolio&.sampled?
            head :unprocessable_entity
            return
          end

          Decidim.traceability.perform_action!("view_participants", stratified_sortition, current_user, visibility: "all")

          head :ok
        end

        private

        def collection
          @collection ||= StratifiedSortition.where(component: current_component)
        end

        def stratified_sortitions
          @stratified_sortitions ||= collection.page(params[:page]).per(10)
        end

        def stratified_sortition
          @stratified_sortition ||= collection.find_by(id: params[:id])
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::StratifiedSortitions::StratifiedSortitionPresenter)
        end

        def blank_stratum
          @blank_stratum ||= Decidim::StratifiedSortitions::Admin::StratumForm.new
        end

        def blank_substratum(stratum_form)
          Decidim::StratifiedSortitions::Admin::SubstratumForm.new(stratum: stratum_form.model)
        end
      end
    end
  end
end
