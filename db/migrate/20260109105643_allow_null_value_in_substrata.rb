# frozen_string_literal: true

class AllowNullValueInSubstrata < ActiveRecord::Migration[7.0]
  def change
    change_table :decidim_stratified_sortitions_substrata, bulk: true do |t|
      t.change_null :value, true
      t.change_default :value, nil
    end
  end
end
