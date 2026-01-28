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

          @stratified_sortition = stratified_sortition
          @sample_participants_count = @stratified_sortition.sample_participants.count
          @last_sample = SampleImport.where(stratified_sortition: @stratified_sortition).order(created_at: :desc).first
          @samples = SampleImport.where(stratified_sortition: @stratified_sortition).order(created_at: :asc)
          @strata_data = strata_data(@stratified_sortition)
          @candidates_data = candidates_data(@stratified_sortition)
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

        def blank_substratum(stratum_form)
          Decidim::StratifiedSortitions::Admin::SubstratumForm.new(stratum: stratum_form.model)
        end

        def strata_data(stratified_sortition)
          stratified_sortition.strata.map do |stratum|
            chart_data = stratum.substrata.map do |substratum|
              weighing_value = substratum.weighing.present? ? substratum.weighing.to_f : 0.0
              label_with_percentage = "#{translated_attribute(substratum.name)} (#{weighing_value}%)"
              [label_with_percentage, weighing_value]
            end
            chart_data = chart_data.reject { |_name, value| value.zero? }
            {
              stratum:,
              chart_data:,
            }
          end
        end

        def candidates_data(stratified_sortition)
          sample_candidates_ids = stratified_sortition.sample_participants.pluck(:id)
          sample_candidates_stratum = Decidim::StratifiedSortitions::SampleParticipantStratum
                                      .where(decidim_stratified_sortitions_sample_participant_id: sample_candidates_ids)
                                      .select(:decidim_stratified_sortitions_sample_participant_id, :decidim_stratified_sortitions_stratum_id, :decidim_stratified_sortitions_substratum_id)
                                      .distinct
                                      .to_a

          by_stratum = sample_candidates_stratum.group_by(&:decidim_stratified_sortitions_stratum_id)
          by_stratum_and_substratum = sample_candidates_stratum.group_by { |s| [s.decidim_stratified_sortitions_stratum_id, s.decidim_stratified_sortitions_substratum_id] }

          stratified_sortition.strata.map do |stratum|
            substrata = stratum.substrata
            total = by_stratum[stratum.id]&.map(&:decidim_stratified_sortitions_sample_participant_id)&.uniq&.count || 0

            chart_data = substrata.map do |substratum|
              ids = (by_stratum_and_substratum[[stratum.id, substratum.id]] || []).map(&:decidim_stratified_sortitions_sample_participant_id).uniq
              count = ids.count
              percentage = total.positive? ? ((count.to_f / total) * 100).round(1) : 0.0
              label = "#{translated_attribute(substratum.name)} (#{percentage}%)"
              [label, count]
            end
            chart_data = chart_data.reject { |_name, value| value.zero? }
            {
              stratum:,
              chart_data:,
            }
          end
        end
      end
    end
  end
end
