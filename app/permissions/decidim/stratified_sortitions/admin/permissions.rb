# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          allow! if permission_action.subject == :stratified_sortitions && read_permission_action?

          allow! if permission_action.subject == :stratified_sortition && create_permission_action?

          allow! if permission_action.subject == :stratified_sortition && edit_permission_action?

          allow! if permission_action.subject == :stratified_sortition && destroy_permission_action?

          allow! if permission_action.subject == :stratified_sortition && publish_permission_action?

          allow! if permission_action.subject == :stratified_sortition && duplicate_permission_action?

          allow! if permission_action.subject == :stratified_sortition && export_permission_action?

          permission_action
        end

        private

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
