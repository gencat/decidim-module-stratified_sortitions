module Decidim
  module StratifiedSortitions
    class SampleParticipantStratum < ApplicationRecord
      belongs_to :sample_participant
      belongs_to :stratum
      belongs_to :substratum, optional: true

      # Add validations or helper methods as needed
    end
  end
end
