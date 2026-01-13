# frozen_string_literal: true

class AddStatusToStratifiedSortitions < ActiveRecord::Migration[7.0]
  def up
    add_column :decidim_stratified_sortitions_stratified_sortitions, :status, :string, default: "pending"
  end

  def down
    remove_column :decidim_stratified_sortitions_stratified_sortitions, :status
  end
end
