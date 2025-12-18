# frozen_string_literal: true

require "decidim/components/namer"
require "decidim/faker/localized"
require "decidim/core/test/factories"

FactoryBot.define do
  # Singular alias factory expected by specs (some tests call :stratified_sortition_component)
  factory :stratified_sortition_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :stratified_sortitions).i18n_name }
    manifest_name { :stratified_sortitions }
    participatory_space { association(:participatory_process, :with_steps) }
  end

  factory :stratified_sortition, class: "Decidim::StratifiedSortitions::StratifiedSortition" do
    title { generate_localized_title }
    description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
    selection_criteria { Decidim::Faker::Localized.wrapped("<p>", "</p>") { Decidim::Faker::Localized.sentence(word_count: 4) } }
    selected_profiles_description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { Decidim::Faker::Localized.sentence(word_count: 4) } }
    num_candidates { rand(1..10) }
    component { association(:stratified_sortition_component) }
  end

  factory :stratum, class: "Decidim::StratifiedSortitions::Stratum" do
    sequence(:name) { |n| "Stratum #{n}" }
    kind { "value" }
    stratified_sortition { association(:stratified_sortition) }
  end

  factory :substratum, class: "Decidim::StratifiedSortitions::Substratum" do
    sequence(:name) { |n| "Substratum #{n}" }
    value { "A" }
    range { "0-10" }
    weighing { 10.0 }
    stratum { association(:stratum) }
  end
end
