# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe StratifiedSortition do
      subject { described_class }

      it "defines a search_text_cont scope" do
        expect(subject).to respond_to(:search_text_cont)
      end

      it "exposes ransackable scopes including :search_text_cont" do
        scopes = subject.ransackable_scopes
        expect(scopes).to include(:search_text_cont)
      end

      it "includes translatable attributes support" do
        expect(subject.included_modules).to include(Decidim::TranslatableAttributes)
      end
    end
  end
end
