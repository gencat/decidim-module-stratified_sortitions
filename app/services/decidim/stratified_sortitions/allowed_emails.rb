# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class AllowedEmails
      ENV_KEY = "STRATIFIED_SORTITIONS_ALLOWED_EMAILS"

      def self.allowed?(email)
        return false if email.blank?

        allowed_emails.include?(normalize(email))
      end

      def self.allowed_emails
        ENV.fetch(ENV_KEY, "")
           .split(",")
           .map { |email| normalize(email) }
           .compact_blank
           .uniq
      end

      def self.normalize(email)
        email.to_s.strip.downcase
      end

      private_class_method :normalize
    end
  end
end
