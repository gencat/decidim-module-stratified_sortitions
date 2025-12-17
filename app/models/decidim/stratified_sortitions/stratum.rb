# frozen_string_literal: true


module Decidim
  module StratifiedSortitions
    class Stratum < ApplicationRecord
      self.table_name = "decidim_stratified_sortitions_strata"

      include Decidim::TranslatableResource
      include Decidim::TranslatableAttributes

      belongs_to :stratified_sortition, class_name: "Decidim::StratifiedSortitions::StratifiedSortition", foreign_key: "decidim_stratified_sortition_id"
      has_many :substrata, class_name: "Decidim::StratifiedSortitions::Substratum", foreign_key: "decidim_stratified_sortitions_stratum_id", dependent: :destroy

      KINDS = %w[value numeric_range].freeze

      translatable_fields :name
    end
  end
end
