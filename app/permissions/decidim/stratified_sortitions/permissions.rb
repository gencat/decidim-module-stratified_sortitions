# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user
        # Delegate the admin permission checks to the admin permissions class
        return Decidim::StratifiedSortitions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin

        allow! if permission_action.subject == :stratified_sortition && answer_permission_action?

        permission_action
      end

      private

      def answer_permission_action?
        permission_action.action == :answer
      end

      def stratified_sortition
        @stratified_sortition ||= context.fetch(:stratified_sortition, nil)
      end
    end
  end
end
