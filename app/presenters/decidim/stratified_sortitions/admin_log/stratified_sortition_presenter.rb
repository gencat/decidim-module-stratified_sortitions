# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module AdminLog
      # This class holds the logic to present a `Decidim::StratifiedSortitions::StratifiedSortition`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you should not need to call this class
      # directly, but here is an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    StratifiedSortitionPresenter.new(action_log, view_helpers).present
      class StratifiedSortitionPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "create", "update", "delete", "duplicate",
               "execute", "export_results", "view_participants",
               "import_sample", "remove_samples"
            "decidim.stratified_sortitions.admin_log.stratified_sortition.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.stratified_sortition"
        end
      end
    end
  end
end
