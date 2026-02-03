# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Leximin
      # Builds constraint matrices and quota structures for the LEXIMIN algorithm.
      #
      # Extracts volunteer information, category memberships, and quota constraints
      # from the database models into efficient data structures for optimization.
      #
      class ConstraintBuilder
        attr_reader :stratified_sortition

        def initialize(stratified_sortition)
          @stratified_sortition = stratified_sortition
          @cached_data = nil
        end

        # Panel size (k) - number of candidates to select
        #
        # @return [Integer]
        def panel_size
          @panel_size ||= stratified_sortition.num_candidates
        end

        # All volunteers in the pool
        #
        # @return [Array<Integer>] volunteer IDs
        def volunteer_ids
          build_cache unless @cached_data
          @cached_data[:volunteer_ids]
        end

        # Number of volunteers
        #
        # @return [Integer]
        def num_volunteers
          volunteer_ids.size
        end

        # All substratum (category) IDs
        #
        # @return [Array<Integer>]
        def category_ids
          build_cache unless @cached_data
          @cached_data[:category_ids]
        end

        # Quota constraints for each category
        # min_quota is always 0, max_quota is calculated from percentage
        #
        # @return [Hash{Integer => Hash{Symbol => Integer}}]
        #   { substratum_id => { min: 0, max: Integer } }
        def quotas
          build_cache unless @cached_data
          @cached_data[:quotas]
        end

        # Membership matrix: which volunteers belong to which categories
        #
        # @return [Hash{Integer => Set<Integer>}]
        #   { volunteer_id => Set of substratum_ids }
        def volunteer_categories
          build_cache unless @cached_data
          @cached_data[:volunteer_categories]
        end

        # Inverse membership: which volunteers belong to a category
        #
        # @return [Hash{Integer => Set<Integer>}]
        #   { substratum_id => Set of volunteer_ids }
        def category_volunteers
          build_cache unless @cached_data
          @cached_data[:category_volunteers]
        end

        # Get volunteer index for ILP variables
        #
        # @param volunteer_id [Integer]
        # @return [Integer] index in the volunteer array
        def volunteer_index(volunteer_id)
          @volunteer_index_map ||= volunteer_ids.each_with_index.to_h
          @volunteer_index_map[volunteer_id]
        end

        # Get category index for constraint rows
        #
        # @param category_id [Integer]
        # @return [Integer] index in the category array
        def category_index(category_id)
          @category_index_map ||= category_ids.each_with_index.to_h
          @category_index_map[category_id]
        end

        # Stratum information for debugging and validation
        #
        # @return [Array<Hash>] Array of stratum info with substrata
        def strata_info
          build_cache unless @cached_data
          @cached_data[:strata_info]
        end

        private

        def build_cache
          @cached_data = {
            volunteer_ids: [],
            category_ids: [],
            quotas: {},
            volunteer_categories: Hash.new { |h, k| h[k] = Set.new },
            category_volunteers: Hash.new { |h, k| h[k] = Set.new },
            strata_info: [],
          }

          load_volunteers
          load_strata_and_quotas
          load_memberships
        end

        def load_volunteers
          @cached_data[:volunteer_ids] = stratified_sortition
                                         .sample_participants
                                         .pluck(:id)
        end

        def load_strata_and_quotas
          stratified_sortition.strata.includes(:substrata).find_each do |stratum|
            stratum_info = {
              id: stratum.id,
              name: stratum.name,
              kind: stratum.kind,
              substrata: [],
            }

            stratum.substrata.each do |substratum|
              @cached_data[:category_ids] << substratum.id

              # Calculate max quota from percentage
              # max_quota_percentage is stored as a string like "25.5" meaning 25.5%
              percentage = substratum.max_quota_percentage.to_f
              max_quota = if percentage > 0
                            (percentage / 100.0 * panel_size).ceil
                          else
                            panel_size # No restriction if percentage is 0 or not set
                          end

              @cached_data[:quotas][substratum.id] = {
                min: 0, # Always 0 as per requirements
                max: max_quota,
              }

              stratum_info[:substrata] << {
                id: substratum.id,
                name: substratum.name,
                percentage:,
                max_quota:,
              }
            end

            @cached_data[:strata_info] << stratum_info
          end
        end

        def load_memberships
          # Load all participant-substratum relationships efficiently
          SampleParticipantStratum
            .where(
              decidim_stratified_sortitions_sample_participant_id: @cached_data[:volunteer_ids]
            )
            .where.not(decidim_stratified_sortitions_substratum_id: nil)
            .pluck(:decidim_stratified_sortitions_sample_participant_id, :decidim_stratified_sortitions_substratum_id)
            .each do |volunteer_id, category_id|
              @cached_data[:volunteer_categories][volunteer_id] << category_id
              @cached_data[:category_volunteers][category_id] << volunteer_id
            end
        end
      end
    end
  end
end
