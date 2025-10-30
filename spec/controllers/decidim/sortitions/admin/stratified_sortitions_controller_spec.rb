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

        describe "show" do
          let(:stratified_sortition) { create(:stratified_sortition) }
          let(:params) do
            {
              component_id: stratified_sortition.component.id,
              participatory_process_slug: stratified_sortition.component.participatory_space.slug,
              id: stratified_sortition.id
            }
          end

          it "renders the show template" do
            get(:show, params:)
            expect(response).to render_template(:show)
          end
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
                decidim_proposals_component_id:,
                title: {
                  en: "Title",
                  es: "Título",
                  ca: "Títol"
                },
                num_candidates: 3,
              }
            }
          end

          context "with invalid params" do
            let(:decidim_proposals_component_id) { nil }

            it "renders the new template" do
              post(:create, params:)
              expect(response).to render_template(:new)
            end
          end

          context "with valid params" do
            let(:proposal_component) { create(:proposal_component, participatory_space: component.participatory_space) }
            let(:decidim_proposals_component_id) { proposal_component.id }

            it "redirects to show newly created sortition" do
              expect(controller).to receive(:redirect_to) do |params|
                expect(params).to eq(action: :show, id: StratifiedSortition.last.id)
              end

              post :create, params:
            end

            it "StratifiedSortition author is the current user" do
              expect(controller).to receive(:redirect_to) do |params|
                expect(params).to eq(action: :show, id: StratifiedSortition.last.id)
              end

              post(:create, params:)
              expect(StratifiedSortition.last.author).to eq(user)
            end
          end
        end

        describe "confirm_destroy" do
          let(:stratified_sortition) { create(:stratified_sortition) }
          let(:params) do
            {
              component_id: stratified_sortition.component.id,
              participatory_process_slug: stratified_sortition.component.participatory_space.slug,
              id: stratified_sortition.id,
            }
          end

          it "renders the confirm_destroy template" do
            get(:confirm_destroy, params:)
            expect(response).to render_template(:confirm_destroy)
          end
        end

        describe "destroy" do
          let(:cancel_reason) do
            {
              en: "Cancel reason",
              es: "Motivo de la cancelación",
              ca: "Motiu de la cancelació"
            }
          end
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              id: stratified_sortition.id,
              stratified_sortition: {
                cancel_reason:
              }
            }
          end

          context "with invalid params" do
            let(:cancel_reason) do
              {
                en: "",
                es: "",
                ca: ""
              }
            end

            it "renders the confirm_destroy template" do
              delete(:destroy, params:)
              expect(response).to render_template(:confirm_destroy)
            end
          end

          context "with valid params" do
            it "redirects to sortitions list newly created sortition" do
              expect(controller).to receive(:redirect_to).with(action: :index)

              delete :destroy, params:
            end
          end
        end

        describe "edit" do
          let(:stratified_sortition) { create(:stratified_sortition) }
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              component_id: stratified_sortition.component.id,
              id: stratified_sortition.id
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
          let(:params) do
            {
              participatory_process_slug: component.participatory_space.slug,
              id: stratified_sortition.id,
              stratified_sortition: {
                title:,
                num_candidates: 3,
              }
            }
          end

          context "with invalid params" do
            let(:title) do
              {
                en: "",
                es: "",
                ca: ""
              }
            end

            it "renders the edit template" do
              patch(:update, params:)
              expect(response).to render_template(:edit)
            end
          end

          context "with valid params" do
            it "redirects to stratified sortitions list newly created stratified sortition" do
              expect(controller).to receive(:redirect_to).with(action: :index)

              patch :update, params:
            end
          end
        end
      end
    end
  end
end
