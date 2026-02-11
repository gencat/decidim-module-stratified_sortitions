# frozen_string_literal: true

require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path = File.expand_path(File.join("spec", "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  # Include LEXIMIN helpers
  config.include LeximinHelpers

  # Exclude performance tests by default
  config.filter_run_excluding performance: true

  # Allow running only performance tests with: rspec --tag performance
  config.define_derived_metadata(file_path: %r{/spec/performance/}) do |metadata|
    metadata[:performance] = true
  end

  # Tag all leximin-related specs
  config.define_derived_metadata(file_path: %r{/spec/services/.*leximin}) do |metadata|
    metadata[:leximin] = true
  end

  # Make RSpec seed available for deterministic tests
  config.before(:each, :leximin) do |_example|
    @rspec_seed = RSpec.configuration.seed
  end

  config.before(:each, :performance) do |_example|
    @rspec_seed = RSpec.configuration.seed
  end
end
