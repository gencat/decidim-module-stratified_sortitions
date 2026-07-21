# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    # Extends Decidim admin permissions so generic component admin endpoints
    # (configuration, permissions, imports/exports, etc.) are also allowlist-protected
    # for stratified_sortitions components.
    module AdminPermissionsExtension
      def permissions
        if disallow_stratified_component_admin_action?
          disallow!
          return permission_action
        end

        super
      end

      private

      def disallow_stratified_component_admin_action?
        return false unless permission_action.scope == :admin
        return false unless restricted_component_subject?

        component = context.fetch(:component, nil) || context.fetch(:current_component, nil)
        return false unless component&.manifest_name.to_s == "stratified_sortitions"

        !Decidim::StratifiedSortitions::AccessControl.allowed_user?(user)
      end

      def restricted_component_subject?
        [:component, :component_data, :share_token, :reminder].include?(permission_action.subject)
      end
    end

    module AdminPermissionsExtensionLoader
      module_function

      def prepend_extension!
        return unless defined?(::Decidim::Admin::Permissions)
        return if ::Decidim::Admin::Permissions.ancestors.include?(::Decidim::StratifiedSortitions::AdminPermissionsExtension)

        ::Decidim::Admin::Permissions.prepend(::Decidim::StratifiedSortitions::AdminPermissionsExtension)
      end
    end
  end
end

Decidim::StratifiedSortitions::AdminPermissionsExtensionLoader.prepend_extension!

if defined?(ActiveSupport::Reloader)
  ActiveSupport::Reloader.to_prepare do
    Decidim::StratifiedSortitions::AdminPermissionsExtensionLoader.prepend_extension!
  end
end
