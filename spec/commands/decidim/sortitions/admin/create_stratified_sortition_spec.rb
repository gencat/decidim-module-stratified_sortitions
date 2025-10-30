# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe CreateStratifiedSortition do
        let(:organization) { create(:organization) }
        let(:author) { create(:user, :admin, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:dice) { ::Faker::Number.between(from: 1, to: 6) }
        let(:target_items) { ::Faker::Number.number(digits: 2) }
        let(:witnesses) { Decidim::Faker::Localized.wrapped("<p>", "</p>") { Decidim::Faker::Localized.sentence(word_count: 4) } }
        let(:additional_info) { Decidim::Faker::Localized.wrapped("<p>", "</p>") { Decidim::Faker::Localized.sentence(word_count: 4) } }
        let(:title) { Decidim::Faker::Localized.sentence(word_count: 3) }
        let(:params) do
          {
            title:,
            num_candidates: 3,
          }
        end

        let(:stratified_sortition_component) { create(:stratified_sortition_component, participatory_space: participatory_process) }

        let(:context) do
          {
            current_component: stratified_sortition_component,
            current_user: author,
          }
        end

        let(:form) { Decidim::StratifiedSortitions::Admin::StratifiedSortitionsForm.from_params(params).with_context(context) }
        let(:command) { described_class.new(form) }

        describe "when the form is not valid" do
          before do
            allow(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "does not create the stratified sortition" do
            expect do
              command.call
            end.not_to(change { StratifiedSortition.where(component: stratified_sortition_component).count })
          end
        end

        describe "when the form is valid" do
          before do
            allow(form).to receive(:invalid?).and_return(false)
          end

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a stratified sortition" do
            expect do
              command.call
            end.to change { StratifiedSortition.where(component: stratified_sortition_component).count }.by(1)
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:create!)
              .with(StratifiedSortition, author, kind_of(Hash), kind_of(Hash))
              .and_call_original

            expect { command.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.version).to be_present
          end

          it "sends a notification to the participatory space followers" do
            follower = create(:user, organization:)
            create(:follow, followable: participatory_process, user: follower)

            allow(Decidim::EventsManager).to receive(:publish)

            command.call
          end
        end
      end
    end
  end
end
