# frozen_string_literal: true

require "spec_helper"

describe Decidim::StratifiedSortitions::Admin::ImportSampleJob do
  subject { described_class.new }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization:) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:component) { create(:stratified_sortition_component, participatory_space: participatory_process) }
  let(:stratified_sortition) { create(:stratified_sortition, component:) }

  let(:gender_stratum) { create(:stratum, stratified_sortition:, kind: "value", name: { ca: "Gènere", es: "Género", en: "Gender" }) }
  let(:age_stratum) { create(:stratum, stratified_sortition:, kind: "numeric_range", name: { ca: "Edat", es: "Edad", en: "Age" }) }

  let!(:male_substratum) { create(:substratum, stratum: gender_stratum, name: { ca: "Home", es: "Hombre", en: "Man" }, value: "H", weighing: "50") }
  let!(:female_substratum) { create(:substratum, stratum: gender_stratum, name: { ca: "Dona", es: "Mujer", en: "Woman" }, value: "D", weighing: "50") }

  let!(:age_18_25) { create(:substratum, name: { ca: "18-25", es: "18-25", en: "18-25" }, stratum: age_stratum, range: "18-25", weighing: "30") }
  let!(:age_26_40) { create(:substratum, name: { ca: "26-40", es: "26-40", en: "26-40" }, stratum: age_stratum, range: "26-40", weighing: "40") }
  let!(:age_41_65) { create(:substratum, name: { ca: "41-65", es: "41-65", en: "41-65" }, stratum: age_stratum, range: "41-65", weighing: "30") }

  let(:csv_content) do
    <<~CSV
      Dada personal 1 (identificador únic),Dada personal 2,Dada personal 3,Dada personal 4,Género_#{gender_stratum.id},Edad_#{age_stratum.id}
      12345671Z,a,b,c,H,18
      12345672Z,d,e,f,D,33
      12345673Z,g,h,i,H,60
    CSV
  end

  let(:file) do
    tempfile = Tempfile.new(["sample", ".csv"])
    tempfile.write(csv_content)
    tempfile.rewind
    file = ActionDispatch::Http::UploadedFile.new(
      tempfile:,
      filename: "sample.csv",
      type: "text/csv"
    )
    file
  end

  let(:filename) { "sample.csv" }

  before do
    allow(Decidim::StratifiedSortitions::Admin::ImportMailer).to receive(:import).and_return(double(deliver_now: true))
  end

  describe "#perform" do
    context "when all rows are valid" do
      it "creates sample import with completed status" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.to change(Decidim::StratifiedSortitions::SampleImport, :count).by(1)

        sample_import = Decidim::StratifiedSortitions::SampleImport.last
        expect(sample_import.status).to eq("completed")
        expect(sample_import.total_rows).to eq(3)
        expect(sample_import.imported_rows).to eq(3)
        expect(sample_import.failed_rows).to eq(0)
        expect(sample_import.import_errors).to be_empty
      end

      it "creates sample participants" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.to change(Decidim::StratifiedSortitions::SampleParticipant, :count).by(3)
      end

      it "creates sample participant strata associations" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.to change(Decidim::StratifiedSortitions::SampleParticipantStratum, :count).by(6)
      end

      it "associates participants with correct substrata for value type" do
        subject.perform(csv_content, filename, stratified_sortition, user)

        participant = Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345671Z")
        gender_association = participant.sample_participant_strata.find_by(decidim_stratified_sortitions_stratum: gender_stratum)

        expect(gender_association.decidim_stratified_sortitions_substratum).to eq(male_substratum)
      end

      it "associates participants with correct substrata for numeric_range type" do
        subject.perform(csv_content, filename, stratified_sortition, user)

        # Participant with age 18 should be in 18-25 range
        participant_1 = Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345671Z")
        age_association_1 = participant_1.sample_participant_strata.find_by(decidim_stratified_sortitions_stratum: age_stratum)
        expect(age_association_1.decidim_stratified_sortitions_substratum).to eq(age_18_25)

        # Participant with age 33 should be in 26-40 range
        participant_2 = Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345672Z")
        age_association_2 = participant_2.sample_participant_strata.find_by(decidim_stratified_sortitions_stratum: age_stratum)
        expect(age_association_2.decidim_stratified_sortitions_substratum).to eq(age_26_40)

        # Participant with age 60 should be in 41-65 range
        participant_3 = Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345673Z")
        age_association_3 = participant_3.sample_participant_strata.find_by(decidim_stratified_sortitions_stratum: age_stratum)
        expect(age_association_3.decidim_stratified_sortitions_substratum).to eq(age_41_65)
      end

      it "sends import notification email" do
        expect(Decidim::StratifiedSortitions::Admin::ImportMailer).to receive(:import).with(user, kind_of(Decidim::StratifiedSortitions::SampleImport))
        subject.perform(csv_content, filename, stratified_sortition, user)
      end
    end

    context "when some rows have invalid data" do
      let(:csv_content) do
        <<~CSV
          Dada personal 1 (identificador únic),Dada personal 2,Dada personal 3,Dada personal 4,Género_#{gender_stratum.id},Edad_#{age_stratum.id}
          12345671Z,a,b,c,H,18
          12345672Z,d,e,f,X,33
          12345673Z,g,h,i,H,100
          12345674Z,j,k,l,D,25
        CSV
      end

      it "creates sample import with failed status" do
        subject.perform(csv_content, filename, stratified_sortition, user)

        sample_import = Decidim::StratifiedSortitions::SampleImport.last
        expect(sample_import.status).to eq("failed")
        expect(sample_import.total_rows).to eq(4)
        expect(sample_import.imported_rows).to eq(2)
        expect(sample_import.failed_rows).to eq(2)
        expect(sample_import.import_errors).not_to be_empty
      end

      it "creates only valid participants" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.to change(Decidim::StratifiedSortitions::SampleParticipant, :count).by(2)

        expect(Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345671Z")).to be_present
        expect(Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345672Z")).to be_nil
        expect(Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345673Z")).to be_nil
        expect(Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345674Z")).to be_present
      end

      it "records error details for failed rows" do
        subject.perform(csv_content, filename, stratified_sortition, user)

        sample_import = Decidim::StratifiedSortitions::SampleImport.last
        expect(sample_import.import_errors.size).to eq(2)

        error = sample_import.import_errors.first
        expect(error["row"]).to be_present
        expect(error["error"]).to be_present
      end
    end

    context "when a row fails mid-processing" do
      let(:csv_content) do
        <<~CSV
          Dada personal 1 (identificador únic),Dada personal 2,Dada personal 3,Dada personal 4,Género_#{gender_stratum.id},Edad_#{age_stratum.id}
          12345671Z,a,b,c,InvalidGender,18
        CSV
      end

      it "does not create participant due to transaction rollback" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.not_to change(Decidim::StratifiedSortitions::SampleParticipant, :count)
      end

      it "does not create any strata associations" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.not_to change(Decidim::StratifiedSortitions::SampleParticipantStratum, :count)
      end
    end

    context "when participant already exists" do
      let!(:existing_participant) do
        create(:sample_participant,
               personal_data_1: "12345671Z",
               decidim_stratified_sortition: stratified_sortition)
      end

      it "updates existing participant instead of creating new one" do
        expect do
          subject.perform(csv_content, filename, stratified_sortition, user)
        end.to change(Decidim::StratifiedSortitions::SampleParticipant, :count).by(2)

        participant = Decidim::StratifiedSortitions::SampleParticipant.find_by(personal_data_1: "12345671Z")
        expect(participant.personal_data_2).to eq("a")
      end
    end
  end

  describe "#find_substratum" do
    context "with value type stratum" do
      it "finds substratum by exact value match" do
        result = subject.send(:find_substratum, gender_stratum, "H")
        expect(result).to eq(male_substratum)
      end

      it "returns nil for non-existent value" do
        result = subject.send(:find_substratum, gender_stratum, "X")
        expect(result).to be_nil
      end
    end

    context "with numeric_range type stratum" do
      it "finds substratum for value at range minimum" do
        result = subject.send(:find_substratum, age_stratum, "18")
        expect(result).to eq(age_18_25)
      end

      it "finds substratum for value at range maximum" do
        result = subject.send(:find_substratum, age_stratum, "25")
        expect(result).to eq(age_18_25)
      end

      it "finds substratum for value in middle of range" do
        result = subject.send(:find_substratum, age_stratum, "30")
        expect(result).to eq(age_26_40)
      end

      it "returns nil for value outside all ranges" do
        result = subject.send(:find_substratum, age_stratum, "100")
        expect(result).to be_nil
      end
    end
  end
end
