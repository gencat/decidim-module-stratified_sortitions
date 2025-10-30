# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module StratifiedSortitions
    # Common logic to sorting resources
    module OrderableStratifiedSortitions
      extend ActiveSupport::Concern

      included do
        include Decidim::Orderable

        private

        def available_orders
          @available_orders ||= %w(random recent)
        end

        def default_order
          "random"
        end

        def reorder(stratified_sortitions)
          case order
          when "recent"
            stratified_sortitions.order("created_at DESC")
          when "random"
            stratified_sortitions.order_randomly(random_seed)
          else
            stratified_sortitions
          end
        end
      end
    end
  end
end
