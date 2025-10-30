# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe DuplicateStratifiedSortition do
        let(:organization) { create(:organization) }
        let(:admin) { create(:user, :admin, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:stratified_sortition_component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
        let!(:stratified_sortition) { create(:stratified_sortition, component: stratified_sortition_component) }

        subject(:command) { described_class.new(stratified_sortition, admin) }

        describe "when duplicating a stratified sortition" do
          it "broadcasts ok and creates a duplicate" do
            expect { command.call }.to broadcast(:ok).and change(Decidim::StratifiedSortitions::StratifiedSortition, :count).by(1)
          end

          it "copies translatable attributes and num_candidates and component" do
            command.call
            duplicated = Decidim::StratifiedSortitions::StratifiedSortition.last

            expect(duplicated.title.except("machine_translations")).to eq(stratified_sortition.title.except("machine_translations"))
            expect(duplicated.description.except("machine_translations")).to eq(stratified_sortition.description.except("machine_translations"))
            expect(duplicated.num_candidates).to eq(stratified_sortition.num_candidates)
            expect(duplicated.component).to eq(stratified_sortition.component)
          end

          it "traces the action, versioning: true" do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(:duplicate, stratified_sortition, admin)
              .and_call_original

            expect { command.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.version).to be_present
          end
        end
      end
    end
  end
end
