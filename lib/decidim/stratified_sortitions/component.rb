# frozen_string_literal: true

require_dependency "decidim/components/namer"
require "decidim/stratified_sortitions/admin"
require "decidim/stratified_sortitions/engine"
require "decidim/stratified_sortitions/admin_engine"

Decidim.register_component(:stratified_sortitions) do |component|
  component.engine = Decidim::StratifiedSortitions::Engine
  component.stylesheet = "decidim/stratified_sortitions/stratified_sortitions"
  component.admin_engine = Decidim::StratifiedSortitions::AdminEngine
  component.icon = "media/images/decidim_stratified_sortitions.svg"

  # component.on(:before_destroy) do |instance|
  #   # Code executed before removing the component
  # end

  component.permissions_class_name = "Decidim::StratifiedSortitions::Permissions"

  # These actions permissions can be configured in the admin panel
  # component.actions = %w()

  component.settings(:global) do |settings|
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :publish_sortitions, type: :boolean, default: true
  end

  component.register_resource(:stratified_sortition) do |resource|
    # Register a optional resource that can be references from other resources.
    resource.model_class_name = "Decidim::StratifiedSortitions::StratifiedSortition"
    resource.card = "decidim/stratified_sortitions/stratified_sortition"
    resource.searchable = true
  end

  # component.register_stat :sortitions_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
  #   Decidim::StratifiedSortitions.count
  # end
end
