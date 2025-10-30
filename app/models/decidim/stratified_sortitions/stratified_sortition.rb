# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # The data store for a StratifiedSortition in the Decidim::StratifiedSortitions component.
    class StratifiedSortition < Decidim::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::FilterableResource
      include Decidim::ScopableResource
      include Decidim::Loggable
      include Decidim::Publicable
      include Decidim::Resourceable
      include Decidim::Searchable
      include Decidim::Traceable
      include Decidim::TranslatableAttributes
      include Decidim::Forms::HasQuestionnaire
      include Decidim::Randomable
      include Decidim::HasUploadValidations


      component_manifest_name "stratified_sortitions"

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

    end
  end
end
