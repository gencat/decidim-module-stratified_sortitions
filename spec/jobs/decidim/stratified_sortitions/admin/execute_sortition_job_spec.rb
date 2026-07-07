# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe ExecuteSortitionJob do
        subject(:job) { described_class.new }

        let(:organization) { create(:organization) }
        let(:user) { create(:user, :admin, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
        let(:stratified_sortition) { create(:stratified_sortition, component:, status: "executing") }

        describe ".queue_name" do
          it "is queued as :stratified_sortitions" do
            expect(described_class.queue_name).to eq("stratified_sortitions")
          end
        end

        describe "#perform" do
          let(:service_result) { double("result", success?: true) }
          let(:fair_service) { double("fair_sortition_service", call: service_result) }

          before do
            allow(FairSortitionService).to receive(:new).with(stratified_sortition).and_return(fair_service)
          end

          context "when the service succeeds" do
            it "sets the sortition status to executed" do
              job.perform(stratified_sortition, user)
              expect(stratified_sortition.reload.status).to eq("executed")
            end

            it "traces the execute action" do
              expect { job.perform(stratified_sortition, user) }
                .to change(Decidim::ActionLog, :count).by(1)
              expect(Decidim::ActionLog.last.action).to eq("execute")
            end
          end

          context "when the service fails" do
            let(:service_result) { double("result", success?: false, error: "Some error") }

            it "sets the sortition status to failed" do
              job.perform(stratified_sortition, user)
              expect(stratified_sortition.reload.status).to eq("failed")
            end

            it "stores the error message" do
              job.perform(stratified_sortition, user)
              expect(stratified_sortition.reload.execution_error).to eq("Some error")
            end

            it "does not trace the execute action" do
              expect { job.perform(stratified_sortition, user) }
                .not_to change(Decidim::ActionLog, :count)
            end
          end
        end
      end
    end
  end
end
