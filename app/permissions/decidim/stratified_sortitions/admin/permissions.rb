# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin
          return permission_action unless stratified_sortitions_access_allowed?

          allow_permission_actions!

          permission_action
        end

        private

        def stratified_sortitions_access_allowed?
          Decidim::StratifiedSortitions::AccessControl.allowed_user?(user)
        end

        def allow_permission_actions!
          allow! if permission_action.subject == :stratified_sortitions && read_permission_action?

          return unless permission_action.subject == :stratified_sortition

          allow! if create_permission_action?
          allow! if edit_permission_action?
          allow! if destroy_permission_action?
          allow! if publish_permission_action?
          allow! if duplicate_permission_action?
          allow! if export_permission_action?
          allow! if upload_sample_permission_action?
        end

        def read_permission_action?
          permission_action.action == :read
        end

        def create_permission_action?
          permission_action.action == :create
        end

        def edit_permission_action?
          permission_action.action == :edit
        end

        def update_permission_action?
          permission_action.action == :update
        end

        def destroy_permission_action?
          permission_action.action == :destroy
        end

        def publish_permission_action?
          permission_action.action == :publish
        end

        def export_permission_action?
          permission_action.action == :export_surveys
        end

        def upload_sample_permission_action?
          permission_action.action == :upload_sample
        end

        def duplicate_permission_action?
          permission_action.action == :duplicate
        end

        def stratified_sortition
          @stratified_sortition ||= context.fetch(:stratified_sortition, nil)
        end
      end
    end
  end
end
