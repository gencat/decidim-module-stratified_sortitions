# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class SampleImport < ApplicationRecord
      self.table_name = "decidim_stratified_sortitions_sample_imports"

      belongs_to :stratified_sortition
      has_many :sample_participants, dependent: :nullify, foreign_key: :decidim_stratified_sortitions_sample_import_id

      enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }
    end
  end
end
