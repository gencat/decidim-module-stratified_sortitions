# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module ParticipatorySpaceRoleConfigOverride
      def component_is_accessible?(manifest_name)
        return false if manifest_name.to_s == ComponentVisibility::MANIFEST_NAME && !ComponentVisibility.allowed_for_user?(user_role)

        super
      end
    end
  end
end
