# Decidim::StratifiedSortitions

## Usage

Simply include it in your Decidim instance.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'decidim-stratified_sortitions'
```

And then execute:

```bash
bundle
```

### System Dependencies

This module uses the COIN-OR CBC solver for the LEXIMIN fair selection algorithm. You need to install CBC on your system:

**Ubuntu/Debian:**
```bash
sudo apt install coinor-cbc coinor-libcbc-dev
```

**macOS (Homebrew):**
```bash
brew install cbc
```

**Fedora/RHEL:**
```bash
sudo dnf install coin-or-Cbc coin-or-Cbc-devel
```

### Import migrations

After installing the gem you must import and execute the migrations bundled with the gem:

```bash
bundle exec rails decidim_stratified_sortitions:install:migrations
bundle exec rails db:migrate
```

## Usage

To generate all the panels and extract the samples at once:

```ruby
result = Decidim::StratifiedSortitions::FairSortitionService.new(sortition).call
result.selected_participants  # Selected participants
result.portfolio              # The persisted PanelPortfolio
```

Execute the sortition in two phases:

```ruby
service = Decidim::StratifiedSortitions::FairSortitionService.new(sortition)

# Phase 1: Generate portfolio (may be slow, run in background)
portfolio_result = service.generate_portfolio
portfolio = portfolio_result.portfolio

# Publish portfolio.panels for transparency

# Phase 2: Public sampling (at the moment)
final_result = service.sample_from_portfolio(
  verification_seed: "hash"
)
final_result.selected_participants
```

## Running tests

Create a dummy app in your application (if not present):

```bash
bundle exec rake test_app
cd spec/decidim_dummy_app/
bundle exec rails decidim_stratified_sortitions:install:migrations
RAILS_ENV=test bundle exec rails db:migrate
```

And run tests:

```bash
# Run all tests
bundle exec rspec spec

# Run only performance tests
bundle exec rspec --tag performance

# Run all tests except performance (default)
bundle exec rspec --tag ~performance

# Run also slow tests
bundle exec rspec --tag performance --tag slow
```

## Contributing

See [Decidim](https://github.com/decidim/decidim).

## License

See [Decidim](https://github.com/decidim/decidim).
