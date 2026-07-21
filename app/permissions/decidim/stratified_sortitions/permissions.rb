# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user
        return permission_action unless allowed_user_email?

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::StratifiedSortitions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin

        allow! if permission_action.subject == :stratified_sortition

        permission_action
      end

      private

      def stratified_sortition
        @stratified_sortition ||= context.fetch(:stratified_sortition, nil)
      end

      def allowed_user_email?
        Decidim::StratifiedSortitions::AllowedEmails.allowed?(user.email)
      end
    end
  end
end
