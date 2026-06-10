# frozen_string_literal: true

require "spec_helper"

describe "Admin upload sample translations", type: :system do
  let(:manifest_name) { "stratified_sortitions" }
  let!(:organization) { create(:organization, default_locale: "ca", available_locales: %w(ca en es)) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(:stratified_sortition_component,
           manifest: Decidim.find_component_manifest(manifest_name),
           participatory_space: participatory_process)
  end
  let!(:stratified_sortition) { create(:stratified_sortition, component:) }

  include_context "when administrating a component"

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user

    stratum = create(:stratum, stratified_sortition:, kind: "value", name: { ca: "Gènere", en: "Gender", es: "Genero" })
    create(:substratum, stratum:, name: { ca: "Home", en: "Man", es: "Hombre" }, value: "H", max_quota_percentage: "100")

    visit "#{manage_component_path(component)}/#{stratified_sortition.id}/upload_sample"
  end

  it "shows the updated translated sample table texts" do
    within ".example-file-census-container" do
      expect(page).to have_content("Dada personal 1 (identificador únic)")
      expect(page).to have_content("Dada personal 2")
      expect(page).to have_content("Dada personal 3")
      expect(page).to have_content("Dada personal 4")
      expect(page).to have_content("Gènere")
      expect(page).to have_content("Edat")

      expect(page).to have_content("11111111X")
      expect(page).to have_content("Nom exemple 1")
      expect(page).to have_content("Telèfon Exemple 1")
      expect(page).to have_content("correu1@exemple.com")
      expect(page).to have_content("Home")
      expect(page).to have_content("45")
    end

    expect(page).not_to have_content("Translation missing")
  end

  it "shows the updated upload form help texts" do
    expect(page).to have_css("*", text: "L'arxiu a carregar ha de seguir les següents instruccions", visible: :all)
    expect(page).to have_css("*", text: "El format del fitxer ha de ser .csv", visible: :all)
    expect(page).to have_css("*", text: "La primera columna és obligatòria", visible: :all)
    expect(page).to have_css("*", text: "En \"Desar\" el sistema realitzarà la càrrega de les dades en segon pla", visible: :all)

    expect(page).not_to have_content("Translation missing")
  end
end
