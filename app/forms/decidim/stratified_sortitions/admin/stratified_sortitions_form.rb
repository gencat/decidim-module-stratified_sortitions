# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # A form object used to create stratified sortitions from the admin dashboard.
      #
      class StratifiedSortitionsForm < Decidim::Form
        include TranslatableAttributes
        include Decidim::HasUploadValidations

        mimic :stratified_sortition

        translatable_attribute :title, String do |field, _locale|
          validates field, length: { in: 5..150 }, if: proc { |resource| resource.send(field).present? }
        end
        translatable_attribute :description, String
        translatable_attribute :selection_criteria, String
        translatable_attribute :selected_profiles_description, String

        attribute :decidim_component_id, Integer
        attribute :num_candidates, Integer

        validates :title, :description, :selection_criteria, :selected_profiles_description, translatable_presence: true
        validates :num_candidates,
                  presence: true,
                  numericality: {
                    only_integer: true,
                    greater_than_or_equal_to: 1,
                  }

        alias organization current_organization

        def map_model(model); end
      end
    end
  end
end
