# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # This is the engine that runs on the administration interface of `decidim_stratified_sorititions`.
    # It mostly handles rendering the created projects associated to a participatory
    # process.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::StratifiedSortitions::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :stratified_sortitions

        root to: "stratified_sortitions#index"
      end

      def load_seed
        nil
      end
    end
  end
end
