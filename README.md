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

## Import migrations

After installing the gem you must import and execute the migrations bundled with the gem:

```bash
bundle exec rails decidim_stratified_sortitions:install:migrations
bundle exec rails db:migrate
```

### Run tests

Create a dummy app in your application (if not present):

```bash
bundle exec rake test_app
cd spec/decidim_dummy_app/
bundle exec rails decidim_stratified_sortitions:install:migrations
RAILS_ENV=test bundle exec rails db:migrate
```

And run tests:

```bash
bundle exec rspec spec
```

## Contributing

See [Decidim](https://github.com/decidim/decidim).

## License

See [Decidim](https://github.com/decidim/decidim).
