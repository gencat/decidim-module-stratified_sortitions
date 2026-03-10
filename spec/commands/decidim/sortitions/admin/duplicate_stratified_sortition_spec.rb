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

          it "copies translatable attributes, num_candidates and component" do
            command.call
            duplicated = Decidim::StratifiedSortitions::StratifiedSortition.last

            expect(duplicated.title.except("machine_translations")).to eq(stratified_sortition.title.except("machine_translations"))
            expect(duplicated.description.except("machine_translations")).to eq(stratified_sortition.description.except("machine_translations"))
            expect(duplicated.num_candidates).to eq(stratified_sortition.num_candidates)
            expect(duplicated.component).to eq(stratified_sortition.component)
          end

          it "sets the duplicated sortition status to pending" do
            command.call
            duplicated = Decidim::StratifiedSortitions::StratifiedSortition.last

            expect(duplicated.status).to eq("pending")
          end

          it "traces the action, versioning: true" do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(:duplicate, stratified_sortition, admin)
              .and_call_original

            expect { command.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.action).to eq("duplicate")
          end

          context "when the sortition has strata and substrata" do
            let!(:stratum1) { create(:stratum, stratified_sortition:, position: 0, name: { en: "Gender" }, kind: "value") }
            let!(:stratum2) { create(:stratum, stratified_sortition:, position: 1, name: { en: "Age" }, kind: "numeric_range") }
            let!(:substratum1a) { create(:substratum, stratum: stratum1, position: 0, name: { en: "Male" }, value: { en: "M" }, max_quota_percentage: "60") }
            let!(:substratum1b) { create(:substratum, stratum: stratum1, position: 1, name: { en: "Female" }, value: { en: "F" }, max_quota_percentage: "60") }
            let!(:substratum2a) { create(:substratum, stratum: stratum2, position: 0, name: { en: "18-30" }, range: "18-30", max_quota_percentage: "50") }

            it "duplicates all strata" do
              expect { command.call }.to change(Decidim::StratifiedSortitions::Stratum, :count).by(2)
            end

            it "duplicates all substrata" do
              expect { command.call }.to change(Decidim::StratifiedSortitions::Substratum, :count).by(3)
            end

            it "copies strata attributes and preserves position order" do
              command.call
              duplicated = Decidim::StratifiedSortitions::StratifiedSortition.last
              duplicated_strata = duplicated.strata.order(:position)

              expect(duplicated_strata.size).to eq(2)
              expect(duplicated_strata[0].name).to eq(stratum1.name)
              expect(duplicated_strata[0].kind).to eq(stratum1.kind)
              expect(duplicated_strata[0].position).to eq(stratum1.position)
              expect(duplicated_strata[1].name).to eq(stratum2.name)
              expect(duplicated_strata[1].kind).to eq(stratum2.kind)
              expect(duplicated_strata[1].position).to eq(stratum2.position)
            end

            it "copies substrata attributes and links them to the new strata" do
              command.call
              duplicated = Decidim::StratifiedSortitions::StratifiedSortition.last
              duplicated_strata = duplicated.strata.order(:position)

              substrata_of_first = duplicated_strata[0].substrata.order(:position)
              expect(substrata_of_first.size).to eq(2)
              expect(substrata_of_first[0].name).to eq(substratum1a.name)
              expect(substrata_of_first[0].value).to eq(substratum1a.value)
              expect(substrata_of_first[0].max_quota_percentage).to eq(substratum1a.max_quota_percentage)
              expect(substrata_of_first[0].position).to eq(substratum1a.position)
              expect(substrata_of_first[1].name).to eq(substratum1b.name)
              expect(substrata_of_first[1].position).to eq(substratum1b.position)

              substrata_of_second = duplicated_strata[1].substrata.order(:position)
              expect(substrata_of_second.size).to eq(1)
              expect(substrata_of_second[0].name).to eq(substratum2a.name)
              expect(substrata_of_second[0].range).to eq(substratum2a.range)
              expect(substrata_of_second[0].max_quota_percentage).to eq(substratum2a.max_quota_percentage)
            end

            it "does not modify the original strata" do
              expect { command.call }.not_to change { stratified_sortition.strata.reload.count }
            end
          end

          context "when the duplicated sortition fails to save" do
            let!(:stratum) { create(:stratum, stratified_sortition:, position: 0) }
            let!(:substratum) { create(:substratum, stratum:, position: 0) }

            before do
              allow_any_instance_of(Decidim::StratifiedSortitions::StratifiedSortition).to receive(:dup).and_wrap_original do |method|
                duped = method.call
                allow(duped).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
                duped
              end
            end

            it "raises an error" do
              expect { command.call }.to raise_error(ActiveRecord::RecordInvalid)
            end

            it "does not create a new sortition" do
              expect {
                begin
                  command.call
                rescue ActiveRecord::RecordInvalid
                  nil
                end
              }.not_to change(Decidim::StratifiedSortitions::StratifiedSortition, :count)
            end

            it "does not duplicate strata or substrata" do
              expect {
                begin
                  command.call
                rescue ActiveRecord::RecordInvalid
                  nil
                end
              }.not_to change(Decidim::StratifiedSortitions::Stratum, :count)

              expect {
                begin
                  command.call
                rescue ActiveRecord::RecordInvalid
                  nil
                end
              }.not_to change(Decidim::StratifiedSortitions::Substratum, :count)
            end
          end
        end
      end
    end
  end
end
