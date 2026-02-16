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
        let(:title) { { en: "Title", es: "Título", ca: "Títol" } }
        let(:description) { { en: "Description", es: "Descripción", ca: "Descripció" } }
        let(:selection_criteria) { { en: "Selection criteria", es: "Criterios de selección", ca: "Criteris de selecció" } }
        let(:selected_profiles_description) { { en: "Profiles", es: "Perfiles", ca: "Perfils" } }
        let(:strata_params) { {} }
        let(:stratified_sortition_id) { nil }

        let(:params) do
          {
            stratified_sortition: {
              id: stratified_sortition_id,
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
              strata: strata_params
            }
          }
        end

        let(:form) { described_class.from_params(params).with_context(current_organization: organization) }

        describe "basic validations" do
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

            it { is_expected.to be_valid }
          end

          context "when selected_profiles_description is blank" do
            let(:selected_profiles_description) { { en: "", es: "", ca: "" } }

            it { is_expected.to be_valid }
          end
        end

        describe "strata immutability validations" do
          let!(:stratified_sortition) { create(:stratified_sortition) }
          let!(:stratum) { create(:stratum, stratified_sortition:, name: { en: "Age" }, kind: "value", position: 0) }
          let!(:substratum) { create(:substratum, stratum:, name: { en: "18-25" }, value: "young", range: nil, position: 0, weighing: "10") }
          let(:stratified_sortition_id) { stratified_sortition.id }

          let(:base_substratum_params) do
            { id: substratum.id, name_en: "18-25", value: "young", range: "", position: 0, max_quota_percentage: "10", deleted: false }
          end

          let(:base_stratum_params) do
            { id: stratum.id, name_en: "Age", kind: "value", position: 0, deleted: false, substrata: { substratum.id.to_s => base_substratum_params } }
          end

          let(:strata_params) { { stratum.id.to_s => stratum_params } }
          let(:stratum_params) { base_stratum_params }

          shared_examples "allows the change" do
            it { is_expected.to be_valid }
          end

          shared_examples "blocks the change with error" do |error_key|
            it { is_expected.to be_invalid }

            it "adds the correct error" do
              form.valid?
              expect(form.errors[:strata]).to include(I18n.t("activemodel.errors.messages.#{error_key}"))
            end
          end

          context "without sample_participants" do
            context "when modifying strata attributes" do
              let(:stratum_params) { base_stratum_params.merge(name_en: "Different", kind: "numeric_range", position: 5) }

              include_examples "allows the change"
            end

            context "when adding a new stratum" do
              let(:strata_params) do
                { stratum.id.to_s => base_stratum_params, "new" => { name_en: "Gender", kind: "value", position: 1, deleted: false, substrata: {} } }
              end

              include_examples "allows the change"
            end

            context "when deleting a stratum" do
              let(:stratum_params) { base_stratum_params.merge(deleted: true, substrata: {}) }

              include_examples "allows the change"
            end
          end

          context "with sample_participants" do
            let!(:sample_participant) { create(:sample_participant, decidim_stratified_sortition: stratified_sortition) }

            context "when no changes are made" do
              include_examples "allows the change"
            end

            context "when changing max_quota_percentage (allowed)" do
              let(:stratum_params) { base_stratum_params.merge(substrata: { substratum.id.to_s => base_substratum_params.merge(max_quota_percentage: "25") }) }

              include_examples "allows the change"
            end

            describe "stratum modifications" do
              context "when adding a stratum" do
                let(:strata_params) do
                  { stratum.id.to_s => base_stratum_params, "new" => { name_en: "Gender", kind: "value", position: 1, deleted: false, substrata: {} } }
                end

                include_examples "blocks the change with error", "cannot_add_strata_with_sample_participants"
              end

              context "when deleting a stratum" do
                let(:stratum_params) { base_stratum_params.merge(deleted: true, substrata: {}) }

                include_examples "blocks the change with error", "cannot_delete_strata_with_sample_participants"
              end

              context "when changing stratum name" do
                let(:stratum_params) { base_stratum_params.merge(name_en: "Different Name") }

                include_examples "blocks the change with error", "cannot_change_stratum_name_with_sample_participants"
              end

              context "when changing stratum kind" do
                let(:stratum_params) { base_stratum_params.merge(kind: "numeric_range") }

                include_examples "blocks the change with error", "cannot_change_stratum_kind_with_sample_participants"
              end

              context "when changing stratum position" do
                let(:stratum_params) { base_stratum_params.merge(position: 5) }

                include_examples "blocks the change with error", "cannot_change_stratum_position_with_sample_participants"
              end
            end

            describe "substratum modifications" do
              context "when adding a substratum" do
                let(:stratum_params) do
                  base_stratum_params.merge(substrata: {
                    substratum.id.to_s => base_substratum_params,
                    "new" => { name_en: "26-35", value: "adult", range: "", position: 1, max_quota_percentage: "15", deleted: false }
                  })
                end

                include_examples "blocks the change with error", "cannot_add_substrata_with_sample_participants"
              end

              context "when deleting a substratum" do
                let(:stratum_params) { base_stratum_params.merge(substrata: { substratum.id.to_s => base_substratum_params.merge(deleted: true) }) }

                include_examples "blocks the change with error", "cannot_delete_substrata_with_sample_participants"
              end

              context "when changing substratum name" do
                let(:stratum_params) { base_stratum_params.merge(substrata: { substratum.id.to_s => base_substratum_params.merge(name_en: "Different") }) }

                include_examples "blocks the change with error", "cannot_change_substratum_name_with_sample_participants"
              end

              context "when changing substratum value" do
                let(:stratum_params) { base_stratum_params.merge(substrata: { substratum.id.to_s => base_substratum_params.merge(value: "different") }) }

                include_examples "blocks the change with error", "cannot_change_substratum_value_with_sample_participants"
              end

              context "when changing substratum range" do
                let!(:substratum) { create(:substratum, stratum:, name: { en: "18-25" }, value: nil, range: "18-25", position: 0, weighing: "10") }
                let(:base_substratum_params) { { id: substratum.id, name_en: "18-25", value: "", range: "18-25", position: 0, max_quota_percentage: "10", deleted: false } }
                let(:stratum_params) { base_stratum_params.merge(substrata: { substratum.id.to_s => base_substratum_params.merge(range: "20-30") }) }

                include_examples "blocks the change with error", "cannot_change_substratum_range_with_sample_participants"
              end

              context "when changing substratum position" do
                let(:stratum_params) { base_stratum_params.merge(substrata: { substratum.id.to_s => base_substratum_params.merge(position: 5) }) }

                include_examples "blocks the change with error", "cannot_change_substratum_position_with_sample_participants"
              end
            end
          end
        end
      end
    end
  end
end
