# frozen_string_literal: true

RSpec.shared_examples "a feasible portfolio" do
  it "has panels" do
    expect(subject.panels).not_to be_empty
  end

  it "has probabilities matching panels count" do
    expect(subject.probabilities.size).to eq(subject.panels.size)
  end

  it "has probabilities summing to 1" do
    expect(subject.probabilities.sum).to be_within(0.001).of(1.0)
  end

  it "has all probabilities non-negative" do
    expect(subject.probabilities).to all(be >= 0)
  end

  it "has panels of correct size" do
    expected_size = sortition.num_candidates
    subject.panels.each do |panel|
      expect(panel.size).to eq(expected_size)
    end
  end

  it "has panels with valid participant IDs" do
    valid_ids = sortition.sample_participants.pluck(:id)
    subject.panels.each do |panel|
      expect(panel).to all(be_in(valid_ids))
    end
  end

  it "has panels with unique participants" do
    subject.panels.each do |panel|
      expect(panel.uniq.size).to eq(panel.size)
    end
  end
end

RSpec.shared_examples "a successful leximin result" do
  it "succeeds" do
    expect(result.success?).to be true
  end

  it "has no error" do
    expect(result.error).to be_nil
  end

  it "has panels" do
    expect(result.panels).not_to be_empty
  end

  it "has probabilities" do
    expect(result.probabilities).not_to be_empty
  end

  it "has selection probabilities for all participants" do
    participant_ids = sortition.sample_participants.pluck(:id)
    # At minimum, participants in panels should have selection probabilities
    panels_participants = result.panels.flatten.uniq
    panels_participants.each do |pid|
      expect(result.selection_probabilities).to have_key(pid)
    end
  end
end

RSpec.shared_examples "a failed leximin result" do
  it "fails" do
    expect(result.success?).to be false
  end

  it "has an error message" do
    expect(result.error).to be_present
  end

  it "has empty panels" do
    expect(result.panels).to be_empty
  end
end

RSpec.shared_examples "quota compliant panels" do
  let(:constraint_builder) { Decidim::StratifiedSortitions::Leximin::ConstraintBuilder.new(sortition) }

  it "generates panels that respect max quotas" do
    subject.panels.each do |panel|
      constraint_builder.category_ids.each do |cat_id|
        quota = constraint_builder.quotas[cat_id]
        count_in_panel = panel.count do |participant_id|
          constraint_builder.volunteer_categories[participant_id]&.include?(cat_id)
        end

        expect(count_in_panel).to be <= quota[:max],
                                  "Panel exceeds max quota for category #{cat_id}: #{count_in_panel} > #{quota[:max]}"
      end
    end
  end
end
