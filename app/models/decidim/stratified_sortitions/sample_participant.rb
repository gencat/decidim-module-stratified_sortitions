module Decidim
  module StratifiedSortitions
    class SampleParticipant < ApplicationRecord
      belongs_to :decidim_stratified_sortition, class_name: "Decidim::StratifiedSortitions::StratifiedSortition"
      belongs_to :sample_import, class_name: "Decidim::StratifiedSortitions::SampleImport", optional: true
      has_many :sample_participant_strata, dependent: :delete_all
    end
  end
end
