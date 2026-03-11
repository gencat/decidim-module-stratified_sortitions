# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe SamplesController do
        routes { Decidim::StratifiedSortitions::AdminEngine.routes }

        let(:component) { stratified_sortition.component }
        let(:stratified_sortition) { create(:stratified_sortition) }
        let(:user) { create(:user, :confirmed, :admin, organization: component.organization) }

        let!(:stratum) do
          create(:stratum, stratified_sortition:, kind: "value", name: { en: "Gender" })
        end
        let!(:substratum) do
          create(:substratum, stratum:, name: { en: "Man" }, value: "M", max_quota_percentage: "50")
        end

        before do
          request.env["decidim.current_organization"] = component.organization
          request.env["decidim.current_component"] = component
          sign_in user, scope: :user
        end

        describe "create (import_sample)" do
          let(:params) do
            {
              id: stratified_sortition.id,
            }
          end

          before do
            allow_any_instance_of(Decidim::StratifiedSortitions::Admin::ImportSample)
              .to receive(:call) { |instance| instance.send(:broadcast, :ok) }
          end

          it "redirects to the upload_sample page" do
            post(:create, params:)
            expect(response).to redirect_to(upload_sample_stratified_sortition_path(stratified_sortition))
          end

          it "traces the import_sample action" do
            expect { post(:create, params:) }
              .to change(Decidim::ActionLog, :count).by(1)
            expect(Decidim::ActionLog.last.action).to eq("import_sample")
          end
        end

        describe "remove_multiple (remove_samples)" do
          let(:params) do
            {
              id: stratified_sortition.id,
            }
          end

          let(:sample_import) { create(:sample_import, stratified_sortition:) }
          let!(:participant) do
            create(:sample_participant,
                   decidim_stratified_sortition: stratified_sortition,
                   decidim_stratified_sortitions_sample_import: sample_import)
          end

          it "redirects to the upload_sample page" do
            delete(:remove_multiple, params:)
            expect(response).to redirect_to(upload_sample_stratified_sortition_path(stratified_sortition))
          end

          it "traces the remove_samples action" do
            expect { delete(:remove_multiple, params:) }
              .to change(Decidim::ActionLog, :count).by(1)
            expect(Decidim::ActionLog.last.action).to eq("remove_samples")
          end

          it "removes the sample participants" do
            expect { delete(:remove_multiple, params:) }
              .to change(Decidim::StratifiedSortitions::SampleParticipant, :count).by(-1)
          end
        end
      end
    end
  end
end
