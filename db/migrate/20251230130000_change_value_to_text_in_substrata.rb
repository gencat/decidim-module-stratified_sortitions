# frozen_string_literal: true

class ChangeValueToTextInSubstrata < ActiveRecord::Migration[7.0]
  def up
    change_column :decidim_stratified_sortitions_substrata, :value, :text
  end

  def down
    change_column :decidim_stratified_sortitions_substrata, :value, :jsonb
  end
end
