# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    begin
      require "mini_magick"
      MiniMagick::Tool::Identify.new
    rescue StandardError => e
      puts "Warning: ImageMagick not available, configuring fallbacks: #{e.class.name}"
      Capybara.save_path = nil

      if defined?(Capybara::Screenshot)
        Capybara::Screenshot.autosave_on_failure = false
        Capybara::Screenshot.screenshot_and_save_page = false
      end

      ENV["DISABLE_IMAGE_PROCESSING"] = "true"
    end

    Capybara.current_session.driver.browser.manage.window.resize_to(1920, 1080) if Capybara.current_driver == :selenium_chrome_headless
  end

  config.before(:each, type: :system) do |_example|
    if ENV["CI"] || ENV["GITHUB_ACTIONS"]
      driven_by :selenium, using: :headless_chrome, screen_size: [1920, 1080] do |driver_options|
        driver_options.add_argument("--no-sandbox")
        driver_options.add_argument("--disable-dev-shm-usage")
        driver_options.add_argument("--disable-gpu")
        driver_options.add_argument("--disable-web-security")
        driver_options.add_argument("--window-size=1920,1080")
        driver_options.add_argument("--headless")
      end
    end
  end

  config.after(:each, type: :system) do |example|
    next unless example.exception

    begin
      Capybara.save_screenshot if defined?(Capybara) && Capybara.respond_to?(:save_screenshot)
    rescue StandardError => e
      puts "Could not save screenshot: #{e.message}"
    end
  end
end
