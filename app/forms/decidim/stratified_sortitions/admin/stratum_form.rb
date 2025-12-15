# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class StratumForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :name, String
        attribute :kind, String
        attribute :deleted, Boolean, default: false

        validates :name, translatable_presence: true, unless: :deleted

        def to_param
          return id if id.present?

          "stratified-sortition-stratum-id"
        end
      end
    end
  end
end
