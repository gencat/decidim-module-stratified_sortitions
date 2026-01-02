# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class SampleParticipant < ApplicationRecord
      belongs_to :decidim_stratified_sortition, class_name: "Decidim::StratifiedSortitions::StratifiedSortition"
      belongs_to :decidim_stratified_sortitions_sample_import, class_name: "Decidim::StratifiedSortitions::SampleImport", optional: true

      has_many :sample_participant_strata, dependent: :destroy, foreign_key: :decidim_stratified_sortitions_sample_participant_id
    end
  end
end
