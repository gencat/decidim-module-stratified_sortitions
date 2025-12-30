module Decidim
  module StratifiedSortitions
    class SampleParticipantStratum < ApplicationRecord
      belongs_to :decidim_stratified_sortitions_sample_participant, class_name: "Decidim::StratifiedSortitions::SampleParticipant"
      belongs_to :decidim_stratified_sortitions_stratum, class_name: "Decidim::StratifiedSortitions::Stratum"
      belongs_to :decidim_stratified_sortitions_substratum, class_name: "Decidim::StratifiedSortitions::Substratum"
    end
  end
end
