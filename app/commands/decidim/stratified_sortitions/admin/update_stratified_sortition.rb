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
          tasks = []

          form.strata_to_persist.each do |stratum|
            stratum_object = Decidim::StratifiedSortitions::Stratum.new(
              stratified_sortition:,
              name: stratum.name,
              kind: stratum.kind
            )
            strata << stratum_object
          end

          stratified_sortition.strata = strata
          stratified_sortition.save!
        end
      end
    end
  end
end
