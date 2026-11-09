# frozen_string_literal: true

require "spec_helper"

describe "Stratified sortitions index page", type: :system do
  let(:manifest_name) { "stratified_sortitions" }
  let!(:organization) { create(:organization, default_locale: "en", available_locales: ["en"]) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(:stratified_sortition_component,
           manifest: Decidim.find_component_manifest(manifest_name),
           participatory_space: participatory_process)
  end
  let(:router) { Decidim::EngineRouter.main_proxy(component) }

  before do
    switch_to_host(organization.host)
  end

  context "when there is only one stratified sortition" do
    let!(:stratified_sortition) { create(:stratified_sortition, component:) }

    it "redirects to the stratified sortition show page" do
      visit router.stratified_sortitions_path

      expect(page).to have_current_path(router.stratified_sortition_path(stratified_sortition))
      expect(page).to have_content(translated(stratified_sortition.title))
    end

    it "redirects when accessing from the component root" do
      visit router.root_path

      expect(page).to have_current_path(router.stratified_sortition_path(stratified_sortition))
    end
  end

  context "when there are several stratified sortitions" do
    let!(:stratified_sortitions) { create_list(:stratified_sortition, 2, component:) }

    it "lists them" do
      visit router.stratified_sortitions_path

      expect(page).to have_current_path(router.stratified_sortitions_path)
      stratified_sortitions.each do |stratified_sortition|
        expect(page).to have_content(translated(stratified_sortition.title))
      end
    end
  end
end
