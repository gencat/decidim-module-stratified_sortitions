# frozen_string_literal: true


module Decidim
  module StratifiedSortitions
    class Stratum < ApplicationRecord
      self.table_name = "decidim_stratified_sortitions_strata"

      include Decidim::TranslatableResource
      include Decidim::TranslatableAttributes

      belongs_to :stratified_sortition, class_name: "Decidim::StratifiedSortitions::StratifiedSortition", foreign_key: "decidim_stratified_sortition_id"
      has_many :substrata, class_name: "Decidim::StratifiedSortitions::Substratum", dependent: :destroy

      KINDS = %w[value numeric_range].freeze

      translatable_fields :name

      validates :name, translatable_presence: true
      validates :kind, presence: true, inclusion: { in: KINDS }
      validates :position, presence: true, numericality: { only_integer: true }
    end
  end
end
