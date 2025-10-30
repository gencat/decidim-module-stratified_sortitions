# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    module Admin
      describe UpdateStratifiedSortition do
        let(:description) { Decidim::Faker::Localized.wrapped("<p>", "</p>") { Decidim::Faker::Localized.sentence(word_count: 4) }.except("machine_translations") }
        let(:title) { Decidim::Faker::Localized.sentence(word_count: 3).except(:machine_translations) }
        let(:stratified_sortition) { create(:stratified_sortition) }
        let(:user) { create(:user, :admin, :confirmed) }
        let(:params) do
          {
            id: stratified_sortition.id,
            stratified_sortition: {
              title:,
              description:,
            },
          }
        end

        let(:context) do
          {
            current_user: user,
            current_component: stratified_sortition.component,
          }
        end

        let(:form) { Decidim::StratifiedSortitions::Admin::StratifiedSortitionsForm.from_params(params).with_context(context) }
        let(:command) { described_class.new(form, stratified_sortition) }

        describe "when the form is not valid" do
          before do
            allow(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        describe "when the form is valid" do
          before do
            allow(form).to receive(:invalid?).and_return(false)
          end

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "Updates the title" do
            command.call
            stratified_sortition.reload
            expect(stratified_sortition.title.except("machine_translations")).to eq(title)
          end

          it "Updates the description" do
            command.call
            stratified_sortition.reload
            expect(stratified_sortition.description.except("machine_translations")).to eq(description)
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:update!)
              .with(stratified_sortition, user, kind_of(Hash))
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
