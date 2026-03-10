# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class SampleUploadForm < Decidim::Form
        include Decidim::HasUploadValidations

        attribute :file, Decidim::Attributes::Blob

        validates :file, presence: true
      end
    end
  end
end
