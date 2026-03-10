# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Command that import samples of a stratified sortition
      class ImportSample < Decidim::Command
        # Public: Initializes the command.
        #
        # form - A SampleUploadForm with the file blob
        # stratified_sortition - The stratified sortition to import samples to
        # user - The user performing the import
        def initialize(form, stratified_sortition, user)
          super()
          @form = form
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
          return broadcast(:invalid) unless @form.valid?

          blob = @form.file
          file_content = blob.download
          filename = blob.filename.to_s

          Decidim::StratifiedSortitions::Admin::ImportSampleJob
            .perform_later(file_content, filename, @stratified_sortition, @user)
          broadcast(:ok)
        end
      end
    end
  end
end
