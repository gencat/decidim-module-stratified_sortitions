# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe ApplicationHelper do
      let(:helper_host) do
        klass = Class.new do
          include ActionView::Helpers::TranslationHelper
          include Decidim::StratifiedSortitions::ApplicationHelper
        end

        klass.new
      end

      describe "#filter_sections_stratified_sortitions" do
        it "builds collection filters with an explicit label" do
          section = helper_host.filter_sections_stratified_sortitions.first

          expect(section).to include(
            method: :with_any_state,
            collection: helper_host.filter_state_values,
            label: I18n.t("state", scope: "decidim.stratified_sortitions.stratified_sortitions.filters"),
            id: "state"
          )
          expect(section).not_to have_key(:label_scope)
        end
      end
    end
  end
end