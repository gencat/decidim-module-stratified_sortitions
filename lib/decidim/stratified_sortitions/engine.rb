# frozen_string_literal: true

require "rails"
require "active_support/all"
require "chartkick"

require "decidim/core"
require "decidim/stratified_sortitions/admin/components_controller_override"
require "decidim/stratified_sortitions/participatory_process_helper_override"
require "decidim/stratified_sortitions/assemblies_helper_override"
require "decidim/stratified_sortitions/participatory_space_role_config_override"

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

      initializer "decidim_stratified_sortitions.hide_component_for_non_allowlisted_users" do
        config.to_prepare do
          Decidim::Admin::ComponentsController.prepend(Decidim::StratifiedSortitions::Admin::ComponentsControllerOverride)
          Decidim::ParticipatorySpaceRoleConfig::Base.prepend(Decidim::StratifiedSortitions::ParticipatorySpaceRoleConfigOverride)

          if defined?(Decidim::ParticipatoryProcesses::ParticipatoryProcessHelper)
            Decidim::ParticipatoryProcesses::ParticipatoryProcessHelper.prepend(Decidim::StratifiedSortitions::ParticipatoryProcessHelperOverride)
          end

          Decidim::Assemblies::AssembliesHelper.prepend(Decidim::StratifiedSortitions::AssembliesHelperOverride) if defined?(Decidim::Assemblies::AssembliesHelper)
        end
      end
    end
  end
end
