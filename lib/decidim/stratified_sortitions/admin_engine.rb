# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # This is the engine that runs on the administration interface of `decidim_stratified_sortitions`.
    # It mostly handles rendering the created projects associated to a participatory
    # process.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::StratifiedSortitions::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :stratified_sortitions do
          post :duplicate, on: :member
          get :upload_sample, on: :member
          post :process_sample, on: :member
        end

        resources :samples, only: [:show, :create] do
          collection do
            get :download_template
          end
        end

        root to: "stratified_sortitions#index"
      end

      initializer "decidim_sstratified_sortitions_admin.mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          mount Decidim::StratifiedSortitions::AdminEngine, at: "/admin", as: "decidim_admin_stratified_sortitions"
        end
      end

      def load_seed
        nil
      end
    end
  end
end
