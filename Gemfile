# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

DECIDIM_VERSION = { git: "https://github.com/decidim/decidim", branch: "release/0.30-stable" }.freeze

gem "decidim", DECIDIM_VERSION
gem "decidim-stratified_sortitions", path: "."

gem "bootsnap", "~> 1.18.6", require: false

# COIN-OR CBC solver for LEXIMIN algorithm (ILP/LP optimization)
gem "puma", ">= 4.3"

gem "chartkick", "~> 5.1.5"

group :development, :test do
  gem "byebug", ">= 11.1.3"
  gem "decidim-dev", DECIDIM_VERSION
  gem "rubocop"
  gem "rubocop-rails"
end

group :development do
  gem "faker"
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 3.5"
end
