# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class Substratum < ApplicationRecord
      self.table_name = "decidim_stratified_sortitions_substrata"

      include Decidim::TranslatableResource
      include Decidim::TranslatableAttributes

      belongs_to :stratum, class_name: "Decidim::StratifiedSortitions::Stratum", foreign_key: "decidim_stratified_sortitions_stratum_id"

      translatable_fields :name, :value
    end
  end
end
