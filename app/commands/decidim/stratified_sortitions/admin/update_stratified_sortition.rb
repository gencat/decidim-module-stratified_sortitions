# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # A command with all the business logic when a user updates a stratified sortition.
      class UpdateStratifiedSortition < Decidim::Command
        include ::Decidim::AttachmentAttributesMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # stratified_sortition - the stratified sortition to update.
        def initialize(form, stratified_sortition)
          super()
          @form = form
          @stratified_sortition = stratified_sortition
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the stratified_sortition.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          transaction do
            update_stratified_sortition
            update_strata(stratified_sortition)
          end

          broadcast(:ok, stratified_sortition)
        end

        private

        attr_reader :form, :stratified_sortition

        def update_stratified_sortition
          Decidim.traceability.update!(
            stratified_sortition,
            form.current_user,
            attributes:
          )
        end

        def attributes
          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_description = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.description, current_organization: form.current_organization).rewrite
          parsed_selection_criteria = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.selection_criteria, current_organization: form.current_organization).rewrite
          parsed_selected_profiles_description = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.selected_profiles_description,
                                                                                                current_organization: form.current_organization).rewrite
          {
            title: parsed_title,
            description: parsed_description,
            selection_criteria: parsed_selection_criteria,
            selected_profiles_description: parsed_selected_profiles_description,
            component: form.current_component,
            num_candidates: form.num_candidates,
          }
        end

        def update_strata(stratified_sortition)
          strata_ids_to_keep = form.strata_to_persist.pluck(:id).compact.map(&:to_i)

          stratified_sortition.strata.each do |existing_stratum|
            next if strata_ids_to_keep.include?(existing_stratum.id)

            existing_stratum.substrata.each do |substratum|
              Decidim::StratifiedSortitions::SampleParticipantStratum.where(
                decidim_stratified_sortitions_substratum_id: substratum.id
              ).destroy_all
            end

            existing_stratum.destroy!
          end

          form.strata_to_persist.each do |stratum_form|
            if stratum_form.id.present?
              stratum_object = Decidim::StratifiedSortitions::Stratum.find_by(
                id: stratum_form.id,
                decidim_stratified_sortition_id: stratified_sortition.id
              )

              if stratum_object
                stratum_object.update!(
                  name: stratum_form.name,
                  kind: stratum_form.kind
                )
              else
                stratum_object = Decidim::StratifiedSortitions::Stratum.create!(
                  stratified_sortition:,
                  name: stratum_form.name,
                  kind: stratum_form.kind
                )
              end
              update_substrata(stratum_object, stratum_form)
            else
              stratum_object = Decidim::StratifiedSortitions::Stratum.create!(
                stratified_sortition:,
                name: stratum_form.name,
                kind: stratum_form.kind
              )
              create_substrata(stratum_object, stratum_form)
            end
          end
        end

        def update_substrata(stratum, stratum_form)
          updated_or_created_ids = []

          stratum_form.substrata_to_persist.each do |substratum_form|
            next if substratum_form.deleted

            if substratum_form.id.present?
              substratum = Decidim::StratifiedSortitions::Substratum.find_by(
                id: substratum_form.id,
                decidim_stratified_sortitions_stratum_id: stratum.id
              )

              if substratum
                substratum.update!(
                  name: substratum_form.name,
                  value: substratum_form.value,
                  range: substratum_form.range,
                  weighing: substratum_form.weighing
                )
                updated_or_created_ids << substratum.id
              else
                new_substratum = Decidim::StratifiedSortitions::Substratum.create!(
                  stratum:,
                  name: substratum_form.name,
                  value: substratum_form.value,
                  range: substratum_form.range,
                  weighing: substratum_form.weighing
                )
                updated_or_created_ids << new_substratum.id
              end
            else
              new_substratum = Decidim::StratifiedSortitions::Substratum.create!(
                stratum:,
                name: substratum_form.name,
                value: substratum_form.value,
                range: substratum_form.range,
                weighing: substratum_form.weighing
              )
              updated_or_created_ids << new_substratum.id
            end
          end

          stratum.substrata.reload.each do |existing_substratum|
            next if updated_or_created_ids.include?(existing_substratum.id)

            Decidim::StratifiedSortitions::SampleParticipantStratum.where(
              decidim_stratified_sortitions_substratum_id: existing_substratum.id
            ).destroy_all

            existing_substratum.destroy!
          end
        end

        def create_substrata(stratum, stratum_form)
          stratum_form.substrata_to_persist.each do |substratum_form|
            Decidim::StratifiedSortitions::Substratum.create!(
              stratum:,
              name: substratum_form.name,
              value: substratum_form.value,
              range: substratum_form.range,
              weighing: substratum_form.weighing
            )
          end
        end
      end
    end
  end
end
