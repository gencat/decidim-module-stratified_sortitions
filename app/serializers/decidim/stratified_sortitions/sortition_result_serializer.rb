# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # Serializer for sortition results export.
    # Includes sortition metadata only in the first row and participant data in each row.
    class SortitionResultSerializer < Decidim::Exporters::Serializer
      # Reset the metadata flag before each export run.
      def self.reset!
        @metadata_serialized = false
      end

      def self.metadata_serialized?
        @metadata_serialized == true
      end

      def self.metadata_serialized!
        @metadata_serialized = true
      end

      # @return [Hash] serialized data for one participant with sortition metadata (only first row)
      def serialize
        participant = resource
        portfolio = participant.decidim_stratified_sortition.panel_portfolio
        audit_log = portfolio.audit_log

        data = if self.class.metadata_serialized?
                 metadata_blank(audit_log)
               else
                 self.class.metadata_serialized!
                 metadata_filled(audit_log)
               end

        data.merge!(participant_data(participant))
        data
      end

      private

      def metadata_filled(audit_log)
        {
          algorithm: audit_log[:algorithm],
          version: audit_log[:version],
          stratified_sortition_id: audit_log[:stratified_sortition_id],
          generated_at: audit_log[:generated_at],
          generation_time_seconds: audit_log[:generation_time_seconds],
          num_panels: audit_log[:num_panels],
          num_iterations: audit_log[:num_iterations],
          convergence_achieved: audit_log[:convergence_achieved],
          selected_at: audit_log[:selected_at],
          selected_panel_index: audit_log[:selected_panel_index],
          verification_seed: audit_log[:verification_seed],
          random_value_used: audit_log[:random_value_used],
          selected_panel_probability: audit_log[:selected_panel_probability],
        }
      end

      def metadata_blank(_audit_log)
        {
          algorithm: nil,
          version: nil,
          stratified_sortition_id: nil,
          generated_at: nil,
          generation_time_seconds: nil,
          num_panels: nil,
          num_iterations: nil,
          convergence_achieved: nil,
          selected_at: nil,
          selected_panel_index: nil,
          verification_seed: nil,
          random_value_used: nil,
          selected_panel_probability: nil,
        }
      end

      def participant_data(participant)
        data = personal_data_fields(participant)
        add_strata_columns(data, participant)
        add_fairness_metrics(data, participant)
        data
      end

      def personal_data_fields(participant)
        {
          personal_data_1: participant.personal_data_1,
          personal_data_2: participant.personal_data_2,
          personal_data_3: participant.personal_data_3,
          personal_data_4: participant.personal_data_4,
        }
      end

      def add_strata_columns(data, participant)
        strata = participant.decidim_stratified_sortition.strata.order(:position)
        strata.each do |stratum|
          ps = participant.sample_participant_strata.find { |s| s.decidim_stratified_sortitions_stratum_id == stratum.id }
          data[:"stratum_#{stratum_key(stratum)}"] = substratum_name_for(ps)
        end
      end

      def stratum_key(stratum)
        stratum.name.values.compact.first || stratum.id.to_s
      end

      def substratum_name_for(participant_stratum)
        participant_stratum&.decidim_stratified_sortitions_substratum&.name&.values&.compact&.first || "-"
      end

      def add_fairness_metrics(data, participant)
        metrics = participant.decidim_stratified_sortition.panel_portfolio.audit_log[:fairness_metrics]
        return if metrics.blank?

        metrics.each { |key, value| data[:"fairness_#{key}"] = value }
      end
    end
  end
end
