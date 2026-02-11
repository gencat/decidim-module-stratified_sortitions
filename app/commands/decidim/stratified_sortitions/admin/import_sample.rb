# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Command that import samples of a stratified sortition
      class ImportSample < Decidim::Command
        # Public: Initializes the command.
        #
        # file - The CSV file to import
        # stratified_sortition - The stratified sortition to import samples to
        # user - The user performing the import
        def initialize(file, stratified_sortition, user)
          super()
          @file = file
          @stratified_sortition = stratified_sortition
          @user = user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          Decidim::StratifiedSortitions::Admin::ImportSampleJob
            .perform_later(@file.read, @file.original_filename, @stratified_sortition, @user)
          broadcast(:ok)
        end
      end
    end
  end
end
