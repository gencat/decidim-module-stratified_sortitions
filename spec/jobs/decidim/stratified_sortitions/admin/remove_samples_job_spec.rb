# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe RemoveSamplesJob do
        subject(:job) { described_class.new }

        let(:organization) { create(:organization) }
        let(:user) { create(:user, :admin, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
        let(:stratified_sortition) { create(:stratified_sortition, component:) }
        let(:sample_import) { create(:sample_import, stratified_sortition:) }
        let!(:participant) do
          create(:sample_participant,
                 decidim_stratified_sortition: stratified_sortition,
                 decidim_stratified_sortitions_sample_import: sample_import)
        end

        describe ".queue_name" do
          it "is queued as :stratified_sortitions" do
            expect(described_class.queue_name).to eq("stratified_sortitions")
          end
        end

        describe "#perform" do
          it "removes the sample participants" do
            expect { job.perform(stratified_sortition, user) }
              .to change(Decidim::StratifiedSortitions::SampleParticipant, :count).by(-1)
          end

          it "removes the sample imports" do
            expect { job.perform(stratified_sortition, user) }
              .to change(Decidim::StratifiedSortitions::SampleImport, :count).by(-1)
          end

          it "traces the remove_samples action" do
            expect { job.perform(stratified_sortition, user) }
              .to change(Decidim::ActionLog, :count).by(1)
            expect(Decidim::ActionLog.last.action).to eq("remove_samples")
          end
        end
      end
    end
  end
end
