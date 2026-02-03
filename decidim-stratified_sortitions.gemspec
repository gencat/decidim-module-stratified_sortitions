# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/stratified_sortitions/version"

Gem::Specification.new do |s|
  s.version = Decidim::StratifiedSortitions.version
  s.authors = ["Oliver Valls"]
  s.email = ["199462+tramuntanal@users.noreply.github.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/gencat/decidim-module-stratified_sortitions"
  s.required_ruby_version = ">= 3.1.1"

  s.name = "decidim-stratified_sortitions"
  s.summary = "A decidim stratified sortitions module"
  s.description = "To-Do"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "chartkick", "~> 5.2.1"
  s.add_dependency "ruby-cbc", "~> 0.3.19"
  s.add_dependency "decidim-admin", Decidim::StratifiedSortitions.decidim_version
  s.add_dependency "decidim-core", Decidim::StratifiedSortitions.decidim_version

  s.metadata["rubygems_mfa_required"] = "true"
end
