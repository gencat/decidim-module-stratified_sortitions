# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module AccessControl
      module_function

      def allowed_user?(user)
        return true unless restriction_enabled?
        return false unless user

        normalized_email = user_email(user)
        normalized_email.present? && allowed_emails.include?(normalized_email)
      end

      def restriction_enabled?
        @restriction_enabled = ENV.fetch("STRATIFIED_SORTITIONS_RESTRICTION_ENABLED", "false") == "true"
        @restriction_enabled
      end

      def allowed_emails
        @allowed_emails ||= ENV.fetch("STRATIFIED_SORTITIONS_ALLOWED_EMAILS", "")
                               .split(/[\s,;]+/)
                               .map { |email| email.strip.downcase }
                               .compact_blank
      end

      def reset_cache!
        @allowed_emails = nil
        @restriction_enabled = nil
      end

      def user_email(user)
        return "" unless user.respond_to?(:email)

        user.email.to_s.strip.downcase
      end

      private_class_method :user_email
    end
  end
end
