# frozen_string_literal: true

require "spec_helper"

describe "Stratified sortition show page", type: :system do
  let(:manifest_name) { "stratified_sortitions" }
  let!(:organization) { create(:organization, default_locale: "en", available_locales: ["en"]) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(:stratified_sortition_component,
           manifest: Decidim.find_component_manifest(manifest_name),
           participatory_space: participatory_process)
  end

  let(:show_path) do
    Decidim::EngineRouter.main_proxy(component).stratified_sortition_path(stratified_sortition)
  end

  before do
    switch_to_host(organization.host)
    visit show_path
  end

  describe "selected_profiles_description section heading" do
    context "when the sortition is executed" do
      let!(:stratified_sortition) do
        create(:stratified_sortition, component:, status: :executed,
               selected_profiles_description: { en: "Some profile description" })
      end

      it "shows the 'selected profiles description' heading" do
        expect(page).to have_content(
          I18n.t("selected_profiles_description", scope: "decidim.stratified_sortitions.stratified_sortitions.show")
        )
        expect(page).not_to have_content(
          I18n.t("to_be_selected_profiles_description", scope: "decidim.stratified_sortitions.stratified_sortitions.show")
        )
      end
    end

    context "when the sortition is not executed" do
      let!(:stratified_sortition) do
        create(:stratified_sortition, component:, status: :pending,
               selected_profiles_description: { en: "Some profile description" })
      end

      it "shows the 'to be selected profiles description' heading" do
        expect(page).to have_content(
          I18n.t("to_be_selected_profiles_description", scope: "decidim.stratified_sortitions.stratified_sortitions.show")
        )
        expect(page).not_to have_content(
          I18n.t("selected_profiles_description", scope: "decidim.stratified_sortitions.stratified_sortitions.show")
        )
      end
    end
  end
end
