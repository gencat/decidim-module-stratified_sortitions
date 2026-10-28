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
        # Core, admin or sortitions may already register these icons
        %w(seedling-line bar-chart-box-line group-line).each do |name|
          next if Decidim.icons.all.has_key?(name)

          Decidim.icons.register(name:, icon: name, category: "system", description: "", engine: :stratified_sortitions)
        end
      end

      initializer "StratifiedSortitions.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
