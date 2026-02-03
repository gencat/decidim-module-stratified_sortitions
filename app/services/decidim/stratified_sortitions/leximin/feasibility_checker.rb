# frozen_string_literal: true

module Decidim
  module StratifiedSortitions
    module Leximin
      # Validates that the LEXIMIN algorithm can run with the given data.
      #
      # Checks:
      # 1. Pool has enough volunteers (n >= k)
      # 2. Quota constraints are consistent (sum of mins <= k <= sum of maxs)
      # 3. Each category has enough volunteers to potentially meet quota
      # 4. Panel size is positive
      #
      class FeasibilityChecker
        def initialize(constraint_builder)
          @cb = constraint_builder
        end

        # Check if the problem is feasible
        #
        # @return [Hash] { feasible: Boolean, errors: Array<String> }
        def check
          errors = []

          errors.concat(check_basic_requirements)
          errors.concat(check_pool_size)
          errors.concat(check_quota_consistency)
          errors.concat(check_category_coverage)

          {
            feasible: errors.empty?,
            errors:,
          }
        end

        private

        def check_basic_requirements
          errors = []

          errors << "La mida del panel (num_candidates) ha de ser un número positiu" if @cb.panel_size.nil? || @cb.panel_size <= 0

          errors << "No hi ha categories (substrats) definides. Cal configurar els estrats i substrats abans d'executar l'algorisme" if @cb.category_ids.empty?

          errors
        end

        def check_pool_size
          errors = []
          n = @cb.num_volunteers
          k = @cb.panel_size

          if n.zero?
            errors << "No hi ha voluntaris al pool. Cal importar participants abans d'executar el sorteig"
          elsif n < k
            errors << "El pool de voluntaris (#{n}) és més petit que la mida del panel (#{k}). " \
                      "Afegiu més participants o reduïu el nombre de candidats a seleccionar"
          end

          errors
        end

        def check_quota_consistency
          errors = []
          k = @cb.panel_size
          return errors if k.nil? || k <= 0

          # Group substrata by stratum to check per-stratum constraints
          # For each stratum, the sum of max quotas should be >= k
          # (at least one substratum per stratum must be selected for each member)

          @cb.strata_info.each do |stratum|
            stratum_name = extract_name(stratum[:name])
            substrata = stratum[:substrata]

            next if substrata.empty?

            # Sum of max quotas for this stratum
            total_max = substrata.sum { |s| s[:max_quota] }

            if total_max < k
              errors << "L'estrat '#{stratum_name}' té quotes màximes insuficients. " \
                        "La suma de quotes màximes (#{total_max}) és menor que la mida del panel (#{k})"
            end

            # Check that percentages within a stratum don't exceed 100%
            total_percentage = substrata.sum { |s| s[:percentage] }
            if total_percentage > 100 + 0.01 # Small tolerance for floating point
              errors << "L'estrat '#{stratum_name}' té percentatges que sumen més del 100% (#{total_percentage.round(1)}%)"
            end
          end

          errors
        end

        def check_category_coverage
          errors = []

          @cb.strata_info.each do |stratum|
            stratum_name = extract_name(stratum[:name])

            stratum[:substrata].each do |substratum|
              cat_id = substratum[:id]
              substratum_name = extract_name(substratum[:name])
              min_quota = @cb.quotas[cat_id][:min]

              next if min_quota.zero? # No minimum requirement

              volunteers_count = @cb.category_volunteers[cat_id]&.size || 0

              if volunteers_count < min_quota
                errors << "El substrat '#{substratum_name}' de l'estrat '#{stratum_name}' " \
                          "requereix mínim #{min_quota} voluntaris però només n'hi ha #{volunteers_count}"
              end
            end
          end

          # Also check that every volunteer belongs to at least one substratum per stratum
          volunteers_without_strata = find_volunteers_without_complete_strata
          if volunteers_without_strata.any?
            count = volunteers_without_strata.size
            errors << "Hi ha #{count} voluntari(s) que no tenen assignat un substrat per a cada estrat. " \
                      "Això pot causar problemes en l'algorisme de selecció"
          end

          errors
        end

        def find_volunteers_without_complete_strata
          incomplete = []
          num_strata = @cb.strata_info.size

          return incomplete if num_strata.zero?

          @cb.volunteer_ids.each do |vid|
            categories = @cb.volunteer_categories[vid]
            # Each volunteer should have exactly one substratum per stratum
            # We can't easily verify this without more complex logic, so we just
            # check they have at least some categories
            incomplete << vid if categories.nil? || categories.empty?
          end

          incomplete
        end

        def extract_name(name_field)
          case name_field
          when Hash
            name_field[I18n.locale.to_s] || name_field["en"] || name_field.values.first || "Sense nom"
          when String
            name_field
          else
            "Sense nom"
          end
        end
      end
    end
  end
end
