# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class SubstratumForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :name, String
        attribute :value, String
        attribute :range, String
        attribute :max_quota_percentage, String
        attribute :deleted, Boolean, default: false
        attribute :position, Integer

        validates :position, numericality: { greater_than_or_equal_to: 0 }

        def to_param
          return id if id.present?

          "stratified-sortition-strata-substratum-id"
        end
      end
    end
  end
end
