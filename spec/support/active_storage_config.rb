# frozen_string_literal: true

# Handle ImageMagick availability in test environment
def configure_active_storage_fallback
  return unless defined?(ActiveStorage)

  ActiveStorage.variant_processor = :mini_magick

  ActiveStorage::Variant.class_eval do
    private

    alias_method :original_transform, :transform

    def transform(file, format: nil)
      original_transform(file, format:)
    rescue MiniMagick::Error => e
      puts "Warning: Could not process image variant due to missing ImageMagick: #{e.message}"
      file
    end
  end
end

if ENV["DISABLE_IMAGE_PROCESSING"] == "true" || ENV["CI"] || ENV["GITHUB_ACTIONS"]
  begin
    require "mini_magick"
    MiniMagick::Tool::Identify.new
  rescue StandardError => e
    puts "Configuring Rails for missing ImageMagick: #{e.class.name}"
    configure_active_storage_fallback
  end
end
