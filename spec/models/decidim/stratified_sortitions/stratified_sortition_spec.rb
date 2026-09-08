# frozen_string_literal: true

require "spec_helper"

module Decidim
  module StratifiedSortitions
    describe StratifiedSortition, type: :model do
      subject(:sortition) { create(:stratified_sortition) }

      describe "soft-deleting the component" do
        let!(:stratum) { create(:stratum, stratified_sortition: sortition) }
        let!(:substratum) { create(:substratum, stratum:) }
        let!(:sample_import) { create(:sample_import, stratified_sortition: sortition) }
        let!(:sample_participant) do
          create(:sample_participant,
                 decidim_stratified_sortition: sortition,
                 decidim_stratified_sortitions_sample_import: sample_import)
        end
        let!(:panel_portfolio) { create(:panel_portfolio, stratified_sortition: sortition) }

        it "keeps the sortition and all its associated records" do
          component = sortition.component
          record_ids = {
            sortition: sortition.id,
            stratum: stratum.id,
            substratum: substratum.id,
            sample_import: sample_import.id,
            sample_participant: sample_participant.id,
            panel_portfolio: panel_portfolio.id,
          }

          component.destroy!

          expect(component).to be_deleted
          expect(StratifiedSortition.find_by(id: record_ids[:sortition])).to be_present
          expect(Stratum.find_by(id: record_ids[:stratum])).to be_present
          expect(Substratum.find_by(id: record_ids[:substratum])).to be_present
          expect(SampleImport.find_by(id: record_ids[:sample_import])).to be_present
          expect(SampleParticipant.find_by(id: record_ids[:sample_participant])).to be_present
          expect(PanelPortfolio.find_by(id: record_ids[:panel_portfolio])).to be_present
        end
      end

      describe "physically destroying the component" do
        let(:component) { sortition.component }

        context "when the sortition has no associated records" do
          it "does not raise an error when destroying the component" do
            expect { component.really_destroy! }.not_to raise_error
          end

          it "destroys the sortition along with the component" do
            sortition_id = sortition.id
            component.really_destroy!
            expect(StratifiedSortition.find_by(id: sortition_id)).to be_nil
          end
        end

        context "when the sortition has strata and substrata" do
          let!(:stratum) { create(:stratum, stratified_sortition: sortition) }
          let!(:substratum) { create(:substratum, stratum:) }

          it "does not raise an error when destroying the component" do
            expect { component.really_destroy! }.not_to raise_error
          end

          it "destroys all associated strata and substrata" do
            stratum_id = stratum.id
            substratum_id = substratum.id
            component.really_destroy!
            expect(Stratum.find_by(id: stratum_id)).to be_nil
            expect(Substratum.find_by(id: substratum_id)).to be_nil
          end
        end

        context "when the sortition has sample imports and participants" do
          let!(:sample_import) { create(:sample_import, stratified_sortition: sortition) }
          let!(:sample_participant) do
            create(:sample_participant,
                   decidim_stratified_sortition: sortition,
                   decidim_stratified_sortitions_sample_import: sample_import)
          end

          it "does not raise an error when destroying the component" do
            expect { component.really_destroy! }.not_to raise_error
          end

          it "destroys all associated sample imports and participants" do
            import_id = sample_import.id
            participant_id = sample_participant.id
            component.really_destroy!
            expect(SampleImport.find_by(id: import_id)).to be_nil
            expect(SampleParticipant.find_by(id: participant_id)).to be_nil
          end
        end

        context "when the sortition has a panel portfolio" do
          let!(:panel_portfolio) { create(:panel_portfolio, stratified_sortition: sortition) }

          it "does not raise an error when destroying the component" do
            expect { component.really_destroy! }.not_to raise_error
          end

          it "destroys the associated panel portfolio" do
            portfolio_id = panel_portfolio.id
            component.really_destroy!
            expect(PanelPortfolio.find_by(id: portfolio_id)).to be_nil
          end
        end

        context "when the sortition has all associated records" do
          let!(:stratum) { create(:stratum, stratified_sortition: sortition) }
          let!(:substratum) { create(:substratum, stratum:) }
          let!(:sample_import) { create(:sample_import, stratified_sortition: sortition) }
          let!(:sample_participant) do
            create(:sample_participant,
                   decidim_stratified_sortition: sortition,
                   decidim_stratified_sortitions_sample_import: sample_import)
          end
          let!(:panel_portfolio) { create(:panel_portfolio, stratified_sortition: sortition) }

          it "does not raise an error when destroying the component" do
            expect { component.really_destroy! }.not_to raise_error
          end

          it "destroys the sortition and all its associated records" do
            sortition_id = sortition.id
            component.really_destroy!
            expect(StratifiedSortition.find_by(id: sortition_id)).to be_nil
          end
        end
      end
    end
  end
end
