# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      module StratifiedSortitionsHelper
        def stratified_sortition_state_css_class(stratified_sortition)
          case stratified_sortition.status
          when "executed" then "success"
          when "executing", "failed" then "alert"
          when "pending" then "warning"
          else "info"
          end
        end
      end
    end
  end
end
