# frozen_string_literal: true

require "spec_helper"

describe "Stratified Sortitions component" do
  subject { component }

  let(:component) { create(:stratified_sortitions_component) }

  context "when create a component" do
    it "save correctly component" do
      expect(component.save!).to be true
    end
  end
end
