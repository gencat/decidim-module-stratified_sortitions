# frozen_string_literal: true

require "decidim/stratified_sortitions/admin"
require "decidim/stratified_sortitions/engine"
require "decidim/stratified_sortitions/admin_engine"
require "decidim/stratified_sortitions/component"

module Decidim
  # Base module for this engine.
  module StratifiedSortitions
    include ActiveSupport::Configurable

    # Public setting that defines how many elements will be shown
    # per page inside the administration view.
    config_accessor :items_per_page do
      15
    end

    def self.derive_random_seed(seed)
      return nil unless seed

      Digest::SHA256.hexdigest(seed).to_i(16) % (2**31)
    end
  end
end
