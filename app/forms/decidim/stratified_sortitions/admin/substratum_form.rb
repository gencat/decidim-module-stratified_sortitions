# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Admin
      # Form object para substrata, necesario para que cocoon y Decidim::Form funcionen bien con asociaciones anidadas.
      class SubstratumForm < Decidim::Form
        mimic :substratum

        def self.reflect_on_association(name)
          Decidim::StratifiedSortitions::Substratum.reflect_on_association(name)
        end
      end
    end
  end
end
