# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable  Lint/ReturnInVoidContext
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

        def substrata
          @substrata ||= []
        end

        def substrata=(value)
          return @substrata = [] if value.blank?

          if value.is_a?(Hash)
            if value.values.first.is_a?(String)
              value = [value]
            else
              value = value.values
            end
          end

          @substrata = value.map do |substratum_data|
            if substratum_data.is_a?(SubstratumForm)
              substratum_data
            elsif substratum_data.is_a?(Hash)
              SubstratumForm.from_params(substratum_data)
            elsif substratum_data.is_a?(Array) && substratum_data[1].is_a?(Hash)
              SubstratumForm.from_params(substratum_data[1])
            else
              next
            end
          end.compact
        end

        def map_model(model)
          super
          self.substrata = model.substrata.map do |substratum|
            Decidim::StratifiedSortitions::Admin::SubstratumForm.from_model(substratum)
          end
        end

        def substrata_to_persist
          substrata.select { |s| s.is_a?(SubstratumForm) && !s.deleted }
        end

        def to_param
          return id if id.present?

          "stratified-sortition-stratum-id"
        end
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable  Lint/ReturnInVoidContext
