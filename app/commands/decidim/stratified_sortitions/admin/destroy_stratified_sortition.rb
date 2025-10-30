# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # This command deals with destroying a StratifiedSortition from the admin panel.
      class DestroyStratifiedSortition < Decidim::Command
        # Public: Initializes the command.
        #
        # page - The StratifiedSortition to be destroyed.
        def initialize(stratified_sortition, current_user)
          super()
          @stratified_sortition = stratified_sortition
          @current_user = current_user
        end

        # Public: Executes the command.
        #
        # Broadcasts :ok if it got destroyed
        # Broadcasts :has_problems if not destroyed 'cause dependent
        # Broadcasts :invalid if it not destroyed
        def call
          destroy_stratified_sortition
          broadcast(:ok)
        rescue ActiveRecord::DeleteRestrictionError
          broadcast(:has_problems)
        rescue ActiveRecord::RecordNotDestroyed
          broadcast(:invalid)
        end

        private

        attr_reader :stratified_sortition, :current_user

        def destroy_stratified_sortition
          transaction do
            Decidim.traceability.perform_action!(
              "delete",
              stratified_sortition,
              current_user
            ) do
              stratified_sortition.destroy!
            end
          end
        end
      end
    end
  end
end
