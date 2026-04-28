# frozen_string_literal: true

# Shared context for component administration tests
RSpec.shared_context "when administrating a component" do
  include Decidim::ComponentTestHelpers

  let(:current_user) { user }

  def visit_component_admin
    visit manage_component_path(component)
  end

  def manage_component_path(component)
    participatory_space = component.participatory_space

    if participatory_space.is_a?(Decidim::ParticipatoryProcess)
      "/admin/participatory_processes/#{participatory_space.slug}/components/#{component.id}/manage/stratified_sortitions"
    elsif participatory_space.is_a?(Decidim::Assembly)
      "/admin/assemblies/#{participatory_space.slug}/components/#{component.id}/manage/stratified_sortitions"
    else
      "/admin/components/#{component.id}/manage/stratified_sortitions"
    end
  end
end
