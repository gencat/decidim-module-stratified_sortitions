# frozen_string_literal: true

require "decidim/components/namer"
require "decidim/faker/localized"
require "decidim/core/test/factories"

FactoryBot.define do
  factory :stratified_sortitions_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :problems).i18n_name }
    manifest_name { :stratified_sortitions }
    participatory_space { association(:participatory_process, :with_steps) }
  end
end
