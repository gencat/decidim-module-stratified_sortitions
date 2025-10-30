# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe DestroyStratifiedSortition do
        let(:organization) { create(:organization) }
        let(:admin) { create(:user, :admin, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:stratified_sortition_component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
        let!(:stratified_sortition) { create(:stratified_sortition, component: stratified_sortition_component) }

        subject(:command) { described_class.new(stratified_sortition, admin) }

        context "when destroy succeeds" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "destroys the stratified_sortition" do
            expect { command.call }.to change { Decidim::StratifiedSortitions::StratifiedSortition.exists?(stratified_sortition.id) }.from(true).to(false)
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability).to receive(:perform_action!).with("delete", stratified_sortition, admin).and_call_original

            expect { command.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.version).to be_present
          end
        end

        context "when destroy is restricted by dependent records" do
          before do
            allow(stratified_sortition).to receive(:destroy!).and_raise(ActiveRecord::DeleteRestrictionError)
          end

          it "broadcasts has_problems" do
            expect { command.call }.to broadcast(:has_problems)
          end
        end

        context "when destroy fails" do
          before do
            allow(stratified_sortition).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end
      end
    end
  end
end
