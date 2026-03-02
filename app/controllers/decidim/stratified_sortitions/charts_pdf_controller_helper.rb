# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # A dummy controller used to render PDF views outside the request cycle.
    # Following the same pattern as Decidim core (decidim-forms).
    # rubocop:disable Rails/ApplicationController
    class ChartsPdfControllerHelper < ActionController::Base
      # rubocop:enable Rails/ApplicationController
      helper Decidim::TranslationsHelper
      helper Decidim::StratifiedSortitions::ChartsPdfHelper

      # Ensure the engine's views (templates + layouts) are found.
      append_view_path Decidim::StratifiedSortitions::Engine.root.join("app", "views")
    end
  end
end
