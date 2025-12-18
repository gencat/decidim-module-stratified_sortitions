# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class StratumForm < Decidim::Form
        include TranslatableAttributes

        translatable_attribute :name, String
        attribute :kind, String
        attribute :deleted, Boolean, default: false
        attribute :substrata, [SubstratumForm]

        validates :name, translatable_presence: true, unless: :deleted

        def map_model(model)
          super
          self.substrata = model.substrata.map do |substratum|
            Decidim::StratifiedSortitions::Admin::SubstratumForm.from_model(substratum)
          end
        end

        def substrata_to_persist
          substrata.reject(&:deleted)
        end

        def to_param
          return id if id.present?

          "stratified-sortition-stratum-id"
        end
      end
    end
  end
end
