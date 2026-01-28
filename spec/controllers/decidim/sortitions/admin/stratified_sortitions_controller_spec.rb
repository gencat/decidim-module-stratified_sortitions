# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe StratifiedSortitionsController do
        routes { Decidim::StratifiedSortitions::AdminEngine.routes }

        let(:component) { stratified_sortition.component }
        let(:stratified_sortition) { create(:stratified_sortition) }
        let(:user) { create(:user, :confirmed, :admin, organization: component.organization) }

        before do
          request.env["decidim.current_organization"] = component.organization
          request.env["decidim.current_component"] = component
          sign_in user, scope: :user
        end

        describe "new" do
          let(:params) do
            { participatory_process_slug: component.participatory_space.slug }
          end

          it "renders the new template" do
            get(:new, params:)
            expect(response).to render_template(:new)
          end
        end

        describe "create" do
          let(:params) do
            {
              participatory_process_slug: stratified_sortition.component.participatory_space.slug,
              stratified_sortition: {
                title: {
                  en: "Title",
                  es: "Título",
                  ca: "Títol",
                },
                description: {
                  en: "<p>Description</p>",
                  es: "<p>Descripción</p>",
                  ca: "<p>Descripció</p>",
                },
                selection_criteria: {
                  en: "<p>Criteria</p>",
                  es: "<p>Criterios</p>",
                  ca: "<p>Criteris</p>",
                },
                selected_profiles_description: {
                  en: "<p>Profiles</p>",
                  es: "<p>Perfiles</p>",
                  ca: "<p>Perfils</p>",
                },
                num_candidates: 3,
              },
            }
          end

          context "with invalid params" do
            let(:params) do
              {
                participatory_process_slug: stratified_sortition.component.participatory_space.slug,
                stratified_sortition: {
                  title: { en: "", es: "", ca: "" },
                  description: { en: "", es: "", ca: "" },
                  selection_criteria: { en: "", es: "", ca: "" },
                  selected_profiles_description: { en: "", es: "", ca: "" },
                  num_candidates: nil,
                },
              }
            end

            it "renders the new template" do
              post(:create, params:)
              expect(response).to render_template(:new)
            end
          end

          context "with valid params" do
            it "redirects to the stratified sortitions list" do
              post(:create, params:)
              expect(response).to redirect_to(stratified_sortitions_path(assembly_slug: -1, component_id: -1))
            end

            it "creates a stratified sortition associated with the current component" do
              post(:create, params:)
              expect(StratifiedSortition.last.component).to eq(component)
            end
          end
        end

        describe "destroy" do
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              id: stratified_sortition.id,
              stratified_sortition:,
            }
          end

          context "with invalid params" do
            let(:cancel_reason) do
              {
                en: "",
                es: "",
                ca: "",
              }
            end

            it "redirects back to the listing with an error flash" do
              delete(:destroy, params:)
              expect(response).to redirect_to(stratified_sortitions_path(assembly_slug: -1, component_id: -1))
            end
          end

          context "with valid params" do
            it "redirects to the stratified sortitions list" do
              delete(:destroy, params:)
              expect(response).to redirect_to(stratified_sortitions_path(assembly_slug: -1, component_id: -1))
            end
          end
        end

        describe "edit" do
          let(:stratified_sortition) { create(:stratified_sortition) }
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              component_id: stratified_sortition.component.id,
              id: stratified_sortition.id,
            }
          end

          it "renders the edit template" do
            get(:edit, params:)
            expect(response).to render_template(:edit)
          end
        end

        describe "update" do
          let(:title) do
            {
              en: "Title",
              es: "Título",
              ca: "Títol",
            }
          end
          let(:description) do
            {
              en: "<p>Description</p>",
              es: "<p>Descripción</p>",
              ca: "<p>Descripció</p>",
            }
          end
          let(:selection_criteria) do
            {
              en: "<p>Criteria</p>",
              es: "<p>Criterios</p>",
              ca: "<p>Criteris</p>",
            }
          end
          let(:selected_profiles_description) do
            {
              en: "<p>Profiles</p>",
              es: "<p>Perfiles</p>",
              ca: "<p>Perfils</p>",
            }
          end
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              id: stratified_sortition.id,
              stratified_sortition: {
                title:, # localized title
                description:,
                selection_criteria:,
                selected_profiles_description:,
                num_candidates: 3,
              },
            }
          end

          context "with invalid params" do
            let(:title) do
              {
                en: "",
                es: "",
                ca: "",
              }
            end

            it "renders the edit template" do
              patch(:update, params:)
              expect(response).to render_template(:edit)
            end
          end

          context "with valid params" do
            it "redirects to stratified sortitions list newly created stratified sortition" do
              patch(:update, params:)
              expect(response).to redirect_to(edit_stratified_sortition_path(stratified_sortition))
            end
          end
        end

        describe "upload_sample" do
          let(:stratified_sortition) { create(:stratified_sortition) }
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              id: stratified_sortition.id,
            }
          end

          before do
            stratum1 = create(:stratum, stratified_sortition:, kind: "value", name: { ca: "Gènere", es: "Género", en: "Gender" })
            substratum1 = create(:substratum, stratum: stratum1, name: { ca: "Home", es: "Hombre", en: "Man" }, value: "H", weighing: "50")
            substratum2 = create(:substratum, stratum: stratum1, name: { ca: "Dona", es: "Mujer", en: "Woman" }, value: "D", weighing: "50")

            sample_import = create(:sample_import, stratified_sortition:)
            participant1 = create(:sample_participant, decidim_stratified_sortition: stratified_sortition, decidim_stratified_sortitions_sample_import: sample_import)
            participant2 = create(:sample_participant, decidim_stratified_sortition: stratified_sortition, decidim_stratified_sortitions_sample_import: sample_import)

            create(:sample_participant_stratum, decidim_stratified_sortitions_sample_participant: participant1, decidim_stratified_sortitions_stratum: stratum1, decidim_stratified_sortitions_substratum: substratum1)
            create(:sample_participant_stratum, decidim_stratified_sortitions_sample_participant: participant2, decidim_stratified_sortitions_stratum: stratum1, decidim_stratified_sortitions_substratum: substratum2)
          end

          it "renders the upload_sample template" do
            get(:upload_sample, params:)
            expect(response).to render_template(:upload_sample)
          end

          it "assigns @stratified_sortition" do
            get(:upload_sample, params:)
            expect(assigns(:stratified_sortition)).to eq(stratified_sortition)
          end

          it "assigns @sample_participants_count" do
            get(:upload_sample, params:)
            expect(assigns(:sample_participants_count)).to eq(stratified_sortition.sample_participants.count)
          end

          it "assigns @strata_data and @candidates_data" do
            get(:upload_sample, params:)
            expect(assigns(:strata_data)).to be_an(Array)
            expect(assigns(:candidates_data)).to be_an(Array)
            expect(assigns(:strata_data).first[:stratum]).to be_present
            expect(assigns(:candidates_data).first[:stratum]).to be_present
          end

          it "@candidates_data refleja los datos importados" do
            get(:upload_sample, params:)
            imported = assigns(:candidates_data).first[:chart_data].map(&:last)
            expect(imported.sum).to eq(stratified_sortition.sample_participants.count)
          end
        end
      end
    end
  end
end
