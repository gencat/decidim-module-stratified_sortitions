# frozen_string_literal: true

# Helper methods for LEXIMIN algorithm testing
module LeximinHelpers
  # Check if CBC solver is available
  def cbc_available?
    require "ruby-cbc"
    true
  rescue LoadError
    false
  end

  # Require CBC solver or fail the test
  def require_cbc!
    raise "CBC solver not installed. Install with: sudo apt install coinor-cbc coinor-libcbc-dev" unless cbc_available?
  end

  # Create a complete sortition setup with strata, substrata, and participants
  #
  # @param num_participants [Integer] Number of participants to create
  # @param panel_size [Integer] Size of the panel to select
  # @param strata_config [Array<Hash>] Configuration for strata
  #   Example: [{ name: "Gender", substrata: [{ name: "Male", percentage: 50 }, { name: "Female", percentage: 50 }] }]
  # @param rspec_seed [Integer] RSpec seed for deterministic assignment
  # @return [Decidim::StratifiedSortitions::StratifiedSortition]
  def create_sortition_with_participants(num_participants:, panel_size:, strata_config:, rspec_seed: nil)
    sortition = create(:stratified_sortition, num_candidates: panel_size)
    random = rspec_seed ? Random.new(rspec_seed) : Random.new

    # Create strata and substrata
    strata_with_substrata = strata_config.map.with_index do |stratum_config, stratum_idx|
      stratum = create(:stratum,
                       stratified_sortition: sortition,
                       name: { en: stratum_config[:name] },
                       kind: "value",
                       position: stratum_idx)

      substrata = stratum_config[:substrata].map.with_index do |sub_config, sub_idx|
        create(:substratum,
               stratum:,
               name: { en: sub_config[:name] },
               value: sub_config[:name],
               max_quota_percentage: sub_config[:percentage].to_s,
               position: sub_idx)
      end

      { stratum:, substrata: }
    end

    # Create participants and assign them to substrata
    num_participants.times do |i|
      participant = create(:sample_participant,
                           decidim_stratified_sortition: sortition,
                           personal_data_1: "participant_#{i}")

      # Assign participant to one substratum per stratum
      strata_with_substrata.each do |stratum_data|
        # Distribute participants according to percentages
        substratum = select_substratum_by_distribution(
          stratum_data[:substrata],
          random
        )

        create(:sample_participant_stratum,
               decidim_stratified_sortitions_sample_participant: participant,
               decidim_stratified_sortitions_stratum: stratum_data[:stratum],
               decidim_stratified_sortitions_substratum: substratum,
               raw_value: substratum.value)
      end
    end

    sortition.reload
  end

  # Create a simple balanced sortition for basic tests
  #
  # @param num_participants [Integer]
  # @param panel_size [Integer]
  # @param rspec_seed [Integer]
  # @return [Decidim::StratifiedSortitions::StratifiedSortition]
  def create_simple_sortition(num_participants: 100, panel_size: 20, rspec_seed: nil)
    create_sortition_with_participants(
      num_participants:,
      panel_size:,
      strata_config: [
        {
          name: "Gender",
          substrata: [
            { name: "Male", percentage: 50 },
            { name: "Female", percentage: 50 },
          ],
        },
        {
          name: "Age",
          substrata: [
            { name: "18-35", percentage: 33 },
            { name: "36-55", percentage: 34 },
            { name: "56+", percentage: 33 },
          ],
        },
      ],
      rspec_seed:
    )
  end

  # Create an infeasible sortition (impossible quotas)
  #
  # @return [Decidim::StratifiedSortitions::StratifiedSortition]
  def create_infeasible_sortition
    sortition = create(:stratified_sortition, num_candidates: 50)

    stratum = create(:stratum,
                     stratified_sortition: sortition,
                     name: { en: "Category" },
                     kind: "value")

    # Create substratum with quota that exceeds pool size
    create(:substratum,
           stratum:,
           name: { en: "Only5" },
           value: "Only5",
           max_quota_percentage: "10") # 10% of 50 = 5, but we only have 5 participants

    # Only create 5 participants
    5.times do |i|
      participant = create(:sample_participant,
                           decidim_stratified_sortition: sortition,
                           personal_data_1: "participant_#{i}")

      create(:sample_participant_stratum,
             decidim_stratified_sortitions_sample_participant: participant,
             decidim_stratified_sortitions_stratum: stratum,
             decidim_stratified_sortitions_substratum: stratum.substrata.first)
    end

    sortition.reload
  end

  private

  def select_substratum_by_distribution(substrata, random)
    # Build cumulative distribution from percentages
    total = substrata.sum { |s| s.max_quota_percentage.to_f }
    return substrata.sample(random:) if total.zero?

    r = random.rand * total
    cumsum = 0.0

    substrata.each do |substratum|
      cumsum += substratum.max_quota_percentage.to_f
      return substratum if r < cumsum
    end

    substrata.last
  end
end

RSpec.configure do |config|
  config.include LeximinHelpers, type: :service
  config.include LeximinHelpers, type: :model
  config.include LeximinHelpers, :leximin
end
