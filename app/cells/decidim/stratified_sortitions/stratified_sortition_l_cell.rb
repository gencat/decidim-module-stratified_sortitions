# frozen_string_literal: true

require "cell/partial"

module Decidim
  module StratifiedSortitions
    # This cell renders a stratified sortition with its L-size card.
    class StratifiedSortitionLCell < Decidim::CardLCell
      include Decidim::StratifiedSortitions::Engine.routes.url_helpers

      private

      def has_state?
        true
      end

      def metadata_cell
        "decidim/stratified_sortitions/stratified_sortition_metadata"
      end
    end
  end
end
