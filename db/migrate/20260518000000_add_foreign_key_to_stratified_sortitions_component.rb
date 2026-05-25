# frozen_string_literal: true

class AddForeignKeyToStratifiedSortitionsComponent < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :decidim_stratified_sortitions_stratified_sortitions,
                    :decidim_components,
                    column: :decidim_component_id,
                    on_delete: :cascade
  end
end
