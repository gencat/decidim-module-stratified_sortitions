# frozen_string_literal: true

require "rails"
require "active_support/all"
require "chartkick"

require "decidim/core"

module Decidim
  module StratifiedSortitions
    # Decidim's StratifiedSortitions Rails Engine.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::StratifiedSortitions

      routes do
        resources :stratified_sortitions, only: [:index, :show]
        scope "/stratified_sortitions" do
          root to: "stratified_sortitions#index"
        end
        get "/", to: redirect("stratified_sortitions", status: 301)
      end

      initializer "decidim_stratified_sortitions.register_icons" do
        Decidim.icons.register(name: "seedling-line", icon: "seedling-line", category: "system", description: "", engine: :stratified_sortitions)
        Decidim.icons.register(name: "bar-chart-box-line", icon: "bar-chart-box-line", category: "system", description: "", engine: :stratified_sortitions)
        Decidim.icons.register(name: "group-line", icon: "group-line", category: "system", description: "", engine: :stratified_sortitions)
      end

      initializer "StratifiedSortitions.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
