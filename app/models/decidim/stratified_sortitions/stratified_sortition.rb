# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class StratifiedSortition < ApplicationRecord
      include Decidim::HasComponent
      include Decidim::FilterableResource
      include Decidim::ScopableResource
      include Decidim::Loggable
      include Decidim::Publicable
      include Decidim::Resourceable
      include Decidim::Searchable
      include Decidim::Traceable
      include Decidim::TranslatableAttributes
      include Decidim::Randomable
      include Decidim::HasUploadValidations

      component_manifest_name "stratified_sortitions"

      has_many :strata, class_name: "Decidim::StratifiedSortitions::Stratum", foreign_key: "decidim_stratified_sortition_id", dependent: :destroy
      has_many :sample_participants, class_name: "Decidim::StratifiedSortitions::SampleParticipant", foreign_key: "decidim_stratified_sortition_id", dependent: :destroy

      scope :search_text_cont, lambda { |search_text|
        where("title ->> '#{I18n.locale}' ILIKE ?", "%#{search_text}%")
      }

      def self.ransackable_scopes(_auth_object = nil)
        [:search_text_cont]
      end

      searchable_fields({
                          participatory_space: :itself,
                          A: :title,
                          B: :description,
                          datetime: :published_at,
                        })

      def strata_and_substrata_configured?
        strata.any? && strata.all? { |stratum| stratum.substrata.any? }
      end
    end
  end
end
