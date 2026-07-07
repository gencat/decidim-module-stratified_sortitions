# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class ExecuteSortitionJob < ApplicationJob
        queue_as :stratified_sortitions

        def perform(stratified_sortition, user)
          result = FairSortitionService.new(stratified_sortition).call
          if result.success?
            stratified_sortition.update!(status: "executed", execution_error: nil)
            Decidim.traceability.perform_action!("execute", stratified_sortition, user, visibility: "all")
          else
            stratified_sortition.update!(status: "failed", execution_error: result.error)
          end
        end
      end
    end
  end
end
