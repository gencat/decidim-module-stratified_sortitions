# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Command that removes uploaded samples of a stratified sortition
      class RemoveUploadedSamples < Decidim::Command
        # Public: Initializes the command.
        #
        # stratified_sortition - The stratified sortition to import samples to
        # user - The user performing the import
        def initialize(stratified_sortition)
          super()
          @stratified_sortition = stratified_sortition
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          remove_participants
          remove_samples
          broadcast(:ok)
        rescue StandardError
          broadcast(:invalid)
        end

        private

        def remove_participants
          Decidim::StratifiedSortitions::SampleParticipant.where(
            decidim_stratified_sortition: @stratified_sortition
          ).destroy_all
        end

        def remove_samples
          Decidim::StratifiedSortitions::SampleImport.where(
            stratified_sortition: @stratified_sortition
          ).destroy_all
        end
      end
    end
  end
end
