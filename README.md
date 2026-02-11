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

Decidim::StratifiedSortitions allows fair sortitions in two ways.

1. Generate all the panels and extract the samples at once.
2. Execute the sortition in two phases

See `Decidim::StratifiedSortitions::FairSortitionService` for more details on how to each workflow works.

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
