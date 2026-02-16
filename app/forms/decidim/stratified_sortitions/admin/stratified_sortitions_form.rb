# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # A form object used to create stratified sortitions from the admin dashboard.
      #
      class StratifiedSortitionsForm < Decidim::Form
        include TranslatableAttributes
        include TranslationsHelper
        include Decidim::HasUploadValidations
        include ApplicationHelper

        mimic :stratified_sortition

        translatable_attribute :title, String do |field, _locale|
          validates field, length: { in: 5..150 }, if: proc { |resource| resource.send(field).present? }
        end
        translatable_attribute :description, String
        translatable_attribute :selection_criteria, String
        translatable_attribute :selected_profiles_description, String

        attribute :id, Integer
        attribute :decidim_component_id, Integer
        attribute :num_candidates, Integer
        attribute :strata, [StratumForm]

        validates :title, :description, translatable_presence: true
        validates :num_candidates,
                  presence: true,
                  numericality: {
                    only_integer: true,
                    greater_than_or_equal_to: 1,
                  }

        alias organization current_organization

        def map_model(model)
          super
          self.strata = model.strata.map do |stratum|
            Decidim::StratifiedSortitions::Admin::StratumForm.from_model(stratum)
          end
        end

        def strata_to_persist
          strata.reject(&:deleted)
        end

        validate :strata_immutable_when_sample_participants_exist

        private

        def strata_immutable_when_sample_participants_exist
          return unless stratified_sortition&.sample_participants&.any?

          validate_strata_count
          validate_strata_attributes
          validate_substrata_changes
        end

        def validate_strata_count
          existing_strata_ids = stratified_sortition.strata.pluck(:id)
          form_strata_ids = strata_to_persist.map { |s| s.id.to_i }.reject(&:zero?)

          new_strata = strata_to_persist.select { |s| s.id.blank? }
          errors.add(:strata, :cannot_add_strata_with_sample_participants) if new_strata.any?

          errors.add(:strata, :cannot_delete_strata_with_sample_participants) if (existing_strata_ids - form_strata_ids).any?
        end

        def validate_strata_attributes
          strata_to_persist.each do |stratum_form|
            next if stratum_form.id.blank?

            existing_stratum = stratified_sortition.strata.find_by(id: stratum_form.id)
            next unless existing_stratum

            errors.add(:strata, :cannot_change_stratum_name_with_sample_participants) unless same_translated_attribute?(existing_stratum.name, stratum_form.name)

            errors.add(:strata, :cannot_change_stratum_kind_with_sample_participants) if existing_stratum.kind != stratum_form.kind

            errors.add(:strata, :cannot_change_stratum_position_with_sample_participants) if existing_stratum.position != stratum_form.position.to_i
          end
        end

        def validate_substrata_changes
          strata_to_persist.each do |stratum_form|
            next if stratum_form.id.blank?

            existing_stratum = stratified_sortition.strata.find_by(id: stratum_form.id)
            next unless existing_stratum

            existing_substrata_ids = existing_stratum.substrata.pluck(:id)
            form_substrata_ids = stratum_form.substrata_to_persist.map { |s| s.id.to_i }.reject(&:zero?)

            new_substrata = stratum_form.substrata_to_persist.select { |s| s.id.blank? }
            errors.add(:strata, :cannot_add_substrata_with_sample_participants) if new_substrata.any?

            errors.add(:strata, :cannot_delete_substrata_with_sample_participants) if (existing_substrata_ids - form_substrata_ids).any?

            validate_substrata_attributes(existing_stratum, stratum_form)
          end
        end

        def validate_substrata_attributes(existing_stratum, stratum_form)
          stratum_form.substrata_to_persist.each do |substratum_form|
            next if substratum_form.id.blank?

            existing_substratum = existing_stratum.substrata.find_by(id: substratum_form.id)
            next unless existing_substratum

            errors.add(:strata, :cannot_change_substratum_name_with_sample_participants) unless same_translated_attribute?(existing_substratum.name, substratum_form.name)

            unless normalize_blank(existing_substratum.value) == normalize_blank(substratum_form.value)
              errors.add(:strata, :cannot_change_substratum_value_with_sample_participants)
            end

            unless normalize_blank(existing_substratum.range) == normalize_blank(substratum_form.range)
              errors.add(:strata, :cannot_change_substratum_range_with_sample_participants)
            end

            errors.add(:strata, :cannot_change_substratum_position_with_sample_participants) if existing_substratum.position != substratum_form.position.to_i
          end
        end

        def normalize_blank(value)
          value.presence
        end

        def same_translated_attribute?(existing_value, form_value)
          return true if existing_value == form_value

          existing_hash = existing_value.is_a?(Hash) ? existing_value : {}
          form_hash = form_value.is_a?(Hash) ? form_value : {}

          existing_hash.stringify_keys == form_hash.stringify_keys
        end

        def stratified_sortition
          @stratified_sortition ||= Decidim::StratifiedSortitions::StratifiedSortition.find_by(id:)
        end
      end
    end
  end
end
