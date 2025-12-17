# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class SubstratumForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :name, String
        translatable_attribute :value, String
        attribute :range, String
        attribute :weighing, String
        attribute :deleted, Boolean, default: false

        def to_param
          return id if id.present?

          "stratified-sortition-strata-substratum-id"
        end
      end
    end
  end
end
