# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe StratifiedSortitionsForm do
        subject { form }

        let(:organization) { build(:organization) }

        let(:num_candidates) { 3 }
        let(:decidim_component_id) { 1 }

        let(:title) do
          {
            en: "Title",
            es: "Título",
            ca: "Títol",
          }
        end

        let(:description) do
          {
            en: "Description",
            es: "Descripción",
            ca: "Descripció",
          }
        end

        let(:selection_criteria) do
          {
            en: "Selection criteria",
            es: "Criterios de selección",
            ca: "Criteris de selecció",
          }
        end

        let(:selected_profiles_description) do
          {
            en: "Profiles",
            es: "Perfiles",
            ca: "Perfils",
          }
        end

        let(:params) do
          {
            stratified_sortition: {
              decidim_component_id:,
              num_candidates:,
              title_en: title[:en],
              title_es: title[:es],
              title_ca: title[:ca],
              description_en: description[:en],
              description_es: description[:es],
              description_ca: description[:ca],
              selection_criteria_en: selection_criteria[:en],
              selection_criteria_es: selection_criteria[:es],
              selection_criteria_ca: selection_criteria[:ca],
              selected_profiles_description_en: selected_profiles_description[:en],
              selected_profiles_description_es: selected_profiles_description[:es],
              selected_profiles_description_ca: selected_profiles_description[:ca],
            },
          }
        end

        let(:form) { described_class.from_params(params).with_context(current_organization: organization) }

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when num_candidates is missing" do
          let(:num_candidates) { nil }

          it { is_expected.to be_invalid }
        end

        context "when num_candidates is not a positive integer" do
          let(:num_candidates) { 0 }

          it { is_expected.to be_invalid }
        end

        context "when title is blank" do
          let(:title) { { en: "", es: "", ca: "" } }

          it { is_expected.to be_invalid }
        end

        context "when description is blank" do
          let(:description) { { en: "", es: "", ca: "" } }

          it { is_expected.to be_invalid }
        end

        context "when selection_criteria is blank" do
          let(:selection_criteria) { { en: "", es: "", ca: "" } }

          it { is_expected.to be_invalid }
        end

        context "when selected_profiles_description is blank" do
          let(:selected_profiles_description) { { en: "", es: "", ca: "" } }

          it { is_expected.to be_invalid }
        end
      end
    end
  end
end
