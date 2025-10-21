# frozen_string_literal: true

require "decidim/components/namer"

module Decidim
  module StratifiedSortitions
    class Seeds
      attr_reader :participatory_space

      def initialize(participatory_space:)
        @participatory_space = participatory_space
      end

      def call
        Decidim::Component.create!(
          name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :stratified_sortitions).i18n_name,
          manifest_name: :stratified_sortitions,
          published_at: Time.current,
          participatory_space:
        )
      end
    end
  end
end
