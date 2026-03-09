# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module StratifiedSortitions
    # Shared logic for computing strata and candidates chart data.
    # Used by both admin and public controllers to avoid duplication.
    module StrataChartsData
      extend ActiveSupport::Concern

      private

      def strata_data(stratified_sortition)
        stratified_sortition.strata.order(:position).map do |stratum|
          chart_data = stratum.substrata.order(:position).map do |substratum|
            quota_value = substratum.max_quota_percentage.present? ? substratum.max_quota_percentage.to_f : 0.0
            label_with_percentage = "#{translated_attribute(substratum.name)} (#{quota_value}%)"
            [label_with_percentage, quota_value]
          end
          chart_data = chart_data.reject { |_name, value| value.zero? }
          {
            stratum:,
            chart_data:,
          }
        end
      end

      def candidates_data(stratified_sortition)
        participant_ids = stratified_sortition.sample_participants.pluck(:id)
        participants_distribution_data(stratified_sortition, participant_ids)
      end

      def results_data(stratified_sortition)
        return stratified_sortition.strata.order(:position).map { |stratum| { stratum:, chart_data: [] } } unless stratified_sortition.panel_portfolio&.sampled?

        selected_ids = stratified_sortition.panel_portfolio.selected_panel
        participants_distribution_data(stratified_sortition, selected_ids)
      end

      def participants_distribution_data(stratified_sortition, participant_ids)
        sample_candidates_stratum = fetch_sample_candidates_stratum(participant_ids)
        by_stratum = group_by_stratum(sample_candidates_stratum)
        by_stratum_and_substratum = group_by_stratum_and_substratum(sample_candidates_stratum)

        stratified_sortition.strata.order(:position).map do |stratum|
          build_stratum_chart(stratum, by_stratum, by_stratum_and_substratum)
        end
      end

      def fetch_sample_candidates_stratum(sample_candidates_ids)
        Decidim::StratifiedSortitions::SampleParticipantStratum
          .where(decidim_stratified_sortitions_sample_participant_id: sample_candidates_ids)
          .select(:decidim_stratified_sortitions_sample_participant_id,
                  :decidim_stratified_sortitions_stratum_id,
                  :decidim_stratified_sortitions_substratum_id)
          .distinct
          .to_a
      end

      def group_by_stratum(sample_candidates_stratum)
        sample_candidates_stratum.group_by(&:decidim_stratified_sortitions_stratum_id)
      end

      def group_by_stratum_and_substratum(sample_candidates_stratum)
        sample_candidates_stratum.group_by do |s|
          [s.decidim_stratified_sortitions_stratum_id, s.decidim_stratified_sortitions_substratum_id]
        end
      end

      def build_stratum_chart(stratum, by_stratum, by_stratum_and_substratum)
        substrata = stratum.substrata.order(:position)
        total = by_stratum[stratum.id]&.map(&:decidim_stratified_sortitions_sample_participant_id)&.uniq&.count || 0
        chart_data = substrata.map do |substratum|
          build_substratum_chart_row(stratum, substratum, by_stratum_and_substratum, total)
        end
        chart_data = chart_data.reject { |_name, value| value.zero? }
        { stratum:, chart_data: }
      end

      def build_substratum_chart_row(stratum, substratum, by_stratum_and_substratum, total)
        ids = (by_stratum_and_substratum[[stratum.id, substratum.id]] || [])
              .map(&:decidim_stratified_sortitions_sample_participant_id).uniq
        count = ids.count
        percentage = total.positive? ? ((count.to_f / total) * 100).round(1) : 0.0
        label = "#{translated_attribute(substratum.name)} (#{percentage}%)"
        [label, count]
      end
    end
  end
end
