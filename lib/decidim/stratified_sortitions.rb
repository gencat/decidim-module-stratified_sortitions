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

    # Link to algorithm used for the sortition
    # config_accessor :stratified_sortition_algorithm do
    #   "https://ruby-doc.org/core-2.4.0/Random.html"
    # end
  end
end
