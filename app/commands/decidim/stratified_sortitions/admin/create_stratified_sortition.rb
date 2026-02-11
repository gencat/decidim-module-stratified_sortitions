# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Command that creates a stratified sortition
      class CreateStratifiedSortition < Decidim::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          super()
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          transaction do
            create_stratified_sortition!
            create_strata(stratified_sortition)
          end

          broadcast(:ok, stratified_sortition)
        end

        private

        attr_reader :form, :stratified_sortition

        def create_stratified_sortition!
          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_description = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.description, current_organization: form.current_organization).rewrite
          parsed_selection_criteria = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.selection_criteria, current_organization: form.current_organization).rewrite
          parsed_selected_profiles_description = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.selected_profiles_description,
                                                                                                current_organization: form.current_organization).rewrite
          params = {
            title: parsed_title,
            description: parsed_description,
            selection_criteria: parsed_selection_criteria,
            selected_profiles_description: parsed_selected_profiles_description,
            component: form.current_component,
            num_candidates: form.num_candidates,
          }

          @stratified_sortition = Decidim.traceability.create!(
            Decidim::StratifiedSortitions::StratifiedSortition,
            form.current_user,
            params,
            visibility: "all"
          )
        end

        def create_strata(stratified_sortition)
          form.strata_to_persist.each do |stratum_form|
            stratum = Decidim::StratifiedSortitions::Stratum.create!(
              stratified_sortition:,
              name: stratum_form.name,
              kind: stratum_form.kind
            )

            stratum_form.substrata_to_persist.each do |substratum_form|
              Decidim::StratifiedSortitions::Substratum.create!(
                stratum:,
                name: substratum_form.name,
                value: substratum_form.value,
                range: substratum_form.range,
                max_quota_percentage: substratum_form.max_quota_percentage
              )
            end
          end
        end
      end
    end
  end
end
