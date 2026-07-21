# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    class ComponentVisibility
      MANIFEST_NAME = "stratified_sortitions"

      def self.allowed_for_user?(user)
        AllowedEmails.allowed?(user&.email)
      end

      def self.visible_component?(component, user)
        return true unless component
        return true unless component.manifest_name.to_s == MANIFEST_NAME

        allowed_for_user?(user)
      end

      def self.filter_manifests_for_user(manifests, user)
        return manifests if allowed_for_user?(user)

        manifests.reject { |manifest| manifest.name.to_s == MANIFEST_NAME }
      end

      def self.filter_components_for_user(components, user)
        return components if allowed_for_user?(user)

        if components.respond_to?(:where)
          components.where.not(manifest_name: MANIFEST_NAME)
        else
          Array(components).reject { |component| component.manifest_name.to_s == MANIFEST_NAME }
        end
      end
    end
  end
end
