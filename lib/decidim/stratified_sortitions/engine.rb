# frozen_string_literal: true

require "rails"
require "active_support/all"

require "decidim/core"

module Decidim
  module StratifiedSortitions
    # Decidim's StratifiedSortitions Rails Engine.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::StratifiedSortitions

      routes do
        root to: "stratified_sortitions#index"
      end

      initializer "decidim_stratified_sortitions.register_icons" do
        Decidim.icons.register(name: "seedling-line", icon: "seedling-line", category: "system", description: "", engine: :stratified_sortitions)
      end

      initializer "StratifiedSortitions.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
