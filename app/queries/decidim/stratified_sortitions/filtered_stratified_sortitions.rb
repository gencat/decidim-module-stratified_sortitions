# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # A class used to find stratified sortitions filtered by components and a date range
    class FilteredStratifiedSortitions < Decidim::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def self.for(components, start_at = nil, end_at = nil)
        new(components, start_at, end_at).query
      end

      # Initializes the class.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      # rubocop:disable Lint/MissingSuper
      def initialize(components, start_at = nil, end_at = nil)
        @components = components
        @start_at = start_at
        @end_at = end_at
      end
      # rubocop:enable Lint/MissingSuper

      # Finds the StratifiedSortitions scoped to an array of components and filtered
      # by a range of dates.
      def query
        stratified_sortitions = Decidim::StratifiedSortitions::StratifiedSortition.where(component: @components)
        stratified_sortitions = stratified_sortitions.where(created_at: @start_at..) if @start_at.present?
        stratified_sortitions = stratified_sortitions.where(created_at: ..@end_at) if @end_at.present?
        stratified_sortitions
      end
    end
  end
end
