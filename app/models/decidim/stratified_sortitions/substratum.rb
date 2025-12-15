# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class Substratum < ApplicationRecord
      self.table_name = "decidim_stratified_sortitions_substrata"

      include Decidim::TranslatableResource
      include Decidim::TranslatableAttributes

      belongs_to :stratum, class_name: "Decidim::StratifiedSortitions::Stratum"

      translatable_fields :name, :value

      validates :name, translatable_presence: true
      validates :value, translatable_presence: true
      validates :weighing, presence: true, numericality: true

      validate :validate_required_field_by_parent_kind

      private

      def validate_required_field_by_parent_kind
        return unless stratum

        case stratum.kind
        when "value"
          errors.add(:value, :blank) if value.blank?
        when "numeric_range"
          errors.add(:range, :blank) if self.range.blank?
        end
      end
    end
  end
end
