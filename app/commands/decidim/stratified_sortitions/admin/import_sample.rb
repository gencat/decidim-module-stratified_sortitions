# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Command that creates a stratified sortition
      class ImportSample < Decidim::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(file, stratified_sortition)
          super()
          @file = file
          @stratified_sortition = stratified_sortition
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          ImportSampleJob.perform_now(@file, stratified_sortition)
          broadcast(:ok)
        end

        private

        def process_row(row)
          id_document = CensusDatum.normalize_and_encode_id_document(row[0])
          date = CensusDatum.parse_date(row[1])

          if id_document.present? && !date.nil?
            data = [id_document, date] + row[2..]
            values << data
          else
            errors << row
          end
        end

        # attr_reader :form, :stratified_sortition

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
          form.strata_to_persist.each do |stratum|
            Decidim::StratifiedSortitions::Stratum.create!(
              stratified_sortition:,
              name: stratum.name,
              kind: stratum.kind
            )
          end
        end
      end
    end
  end
end
