# frozen_string_literal: true

class AllowNullValueInSubstrata < ActiveRecord::Migration[7.0]
  def change
    change_column_null :decidim_stratified_sortitions_substrata, :value, true
    change_column_default :decidim_stratified_sortitions_substrata, :value, nil
  end
end
