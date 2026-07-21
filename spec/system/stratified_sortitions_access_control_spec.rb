# frozen_string_literal: true

require "spec_helper"

describe "Stratified sortitions access control", type: :system do
  let(:manifest_name) { "stratified_sortitions" }
  let!(:organization) { create(:organization, default_locale: "en", available_locales: ["en"]) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(:stratified_sortition_component,
           manifest: Decidim.find_component_manifest(manifest_name),
           participatory_space: participatory_process)
  end
  let!(:stratified_sortition) { create(:stratified_sortition, component:) }
  let(:show_path) { Decidim::EngineRouter.main_proxy(component).stratified_sortition_path(stratified_sortition) }

  include_context "when administrating a component"

  before do
    switch_to_host(organization.host)
    ENV["STRATIFIED_SORTITIONS_ALLOWED_EMAILS"] = "allowed@example.com"
    Decidim::StratifiedSortitions::AccessControl.reset_cache!
  end

  after do
    ENV.delete("STRATIFIED_SORTITIONS_ALLOWED_EMAILS")
    Decidim::StratifiedSortitions::AccessControl.reset_cache!
  end

  it "blocks anonymous access to the public page" do
    visit show_path

    expect(page).to have_content(I18n.t("actions.unauthorized", scope: "decidim.core"))
  end

  it "blocks non-allowlisted access to the admin area" do
    user = create(:user, :confirmed, organization:, email: "blocked@example.com")
    login_as user, scope: :user

    visit manage_component_path(component)

    expect(page).to have_content(I18n.t("actions.unauthorized", scope: "decidim.core"))
  end
end
