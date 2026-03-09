# frozen_string_literal: true

require "cell/partial"

module Decidim
  module StratifiedSortitions
    # This cell renders the card for an instance of a StratifiedSortition
    # the default size is the Large Card (:l)
    class StratifiedSortitionCell < Decidim::ViewModel
      def show
        cell card_size, model, @options
      end

      private

      def card_size
        "decidim/stratified_sortitions/stratified_sortition_l"
      end
    end
  end
end
