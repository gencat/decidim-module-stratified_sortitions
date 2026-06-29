# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class RemoveSamplesJob < ApplicationJob
        queue_as :default

        def perform(stratified_sortition, user)
          RemoveUploadedSamples.call(stratified_sortition) do
            on(:ok) do
              Decidim.traceability.perform_action!("remove_samples", stratified_sortition, user, visibility: "all")
            end
          end
        end
      end
    end
  end
end
