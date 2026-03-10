# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # A command with all the business logic when a user duplicates a stratified sortition.
      class DuplicateStratifiedSortition < Decidim::Command
        include ::Decidim::AttachmentAttributesMethods

        # Public: Initializes the command.
        #
        # stratified_sortition - the stratified sortition to update.
        # current_user - the user performing the duplication.
        def initialize(stratified_sortition, current_user)
          super()
          @stratified_sortition = stratified_sortition
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the duplicated_stratified_sortition.
        #
        # Returns nothing.
        def call
          transaction do
            duplicate_stratified_sortition
          end

          broadcast(:ok)
        end

        private

        attr_reader :stratified_sortition, :current_user

        def duplicate_stratified_sortition
          @stratified_sortition = Decidim.traceability.perform_action!(
            :duplicate,
            stratified_sortition,
            current_user,
          ) do
            @duplicated_stratified_sortition = stratified_sortition.dup
            @duplicated_stratified_sortition.status = :pending
            if @duplicated_stratified_sortition.save!
              duplicate_strata
              @duplicated_stratified_sortition
            else
              broadcast(:invalid)
            end
          end
        end

        def duplicate_strata
          stratified_sortition.strata.order(:position).each do |stratum|
            new_stratum = stratum.dup
            new_stratum.decidim_stratified_sortition_id = @duplicated_stratified_sortition.id
            new_stratum.save!

            duplicate_substrata(stratum, new_stratum)
          end
        end

        def duplicate_substrata(stratum, new_stratum)
          stratum.substrata.order(:position).each do |substratum|
            new_substratum = substratum.dup
            new_substratum.decidim_stratified_sortitions_stratum_id = new_stratum.id
            new_substratum.save!
          end
        end
      end
    end
  end
end
