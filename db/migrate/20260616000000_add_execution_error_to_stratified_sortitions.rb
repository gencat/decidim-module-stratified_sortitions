# frozen_string_literal: true

class AddExecutionErrorToStratifiedSortitions < ActiveRecord::Migration[7.0]
  def up
    add_column :decidim_stratified_sortitions_stratified_sortitions, :execution_error, :text
  end

  def down
    remove_column :decidim_stratified_sortitions_stratified_sortitions, :execution_error
  end
end
