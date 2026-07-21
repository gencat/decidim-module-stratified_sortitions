# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        if stratified_sortition_subject? && !stratified_sortitions_access_allowed?
          disallow!
          return permission_action
        end

        return permission_action unless user
        # Delegate the admin permission checks to the admin permissions class
        return Decidim::StratifiedSortitions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin

        allow! if permission_action.subject == :stratified_sortition

        permission_action
      end

      private

      def stratified_sortitions_access_allowed?
        Decidim::StratifiedSortitions::AccessControl.allowed_user?(user)
      end

      def stratified_sortition_subject?
        permission_action.subject == :stratified_sortition
      end

      def stratified_sortition
        @stratified_sortition ||= context.fetch(:stratified_sortition, nil)
      end
    end
  end
end
