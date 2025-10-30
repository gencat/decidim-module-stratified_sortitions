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
              }
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
                }
              }
            end

            it "renders the new template" do
              post(:create, params: params)
              expect(response).to render_template(:new)
            end
          end

          context "with valid params" do
            it "redirects to the stratified sortitions list" do
              post(:create, params: params)
              expect(response).to redirect_to(stratified_sortitions_path(assembly_slug: -1, component_id: -1))
            end

            it "creates a stratified sortition associated with the current component" do
              post(:create, params: params)
              expect(StratifiedSortition.last.component).to eq(component)
            end
          end
        end

        describe "destroy" do
          let(:cancel_reason) do
            {
              en: "Cancel reason",
              es: "Motivo de la cancelación",
              ca: "Motiu de la cancelació",
            }
          end
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              id: stratified_sortition.id,
              stratified_sortition: {
                cancel_reason:,
              }
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
              delete(:destroy, params: params)
              expect(response).to redirect_to(stratified_sortitions_path(assembly_slug: -1, component_id: -1))
            end
          end

          context "with valid params" do
            it "redirects to the stratified sortitions list" do
              delete(:destroy, params: params)
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
              }
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
              patch(:update, params: params)
              expect(response).to redirect_to(stratified_sortitions_path(assembly_slug: -1, component_id: -1))
            end
          end
        end
      end
    end
  end
end
