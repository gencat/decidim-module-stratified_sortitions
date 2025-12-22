# frozen_string_literal: true

class CreateSampleParticipantStrata < ActiveRecord::Migration[7.0]
  def change
    create_table :decidim_stratified_sortitions_sample_participant_strata do |t|
      t.references :decidim_stratified_sortitions_sample_participant, null: false, foreign_key: true, index: { name: "idx_sample_part_strata_on_participants" }
      t.references :decidim_stratified_sortitions_stratum, null: false, foreign_key: true, index: { name: "idx_sample_part_strata_on_strata" }
      t.references :decidim_stratified_sortitions_substratum,
                   null: true,
                   foreign_key: { to_table: :decidim_stratified_sortitions_substrata },
                   index: { name: "idx_sample_part_strata_on_substrata" }
      t.string :raw_value
      t.timestamps
    end
    # add_index :decidim_sample_participant_strata,
    #           [:decidim_stratified_sortitions_strata_id, :decidim_stratified_sortitions_substrata_id],
    #           name: "idx_sample_part_strata_on_strata_substrata"

    # add_index :decidim_sample_participant_strata,
    #           [:decidim_sample_participant_id, :decidim_stratified_sortitions_strata_id],
    #           unique: true,
    #           name: "idx_sample_part_strata_on_participant_strata"

    # add_index :decidim_sample_participant_strata,
    #           [:decidim_stratified_sortitions_strata_id, :raw_value],
    #           name: "idx_sample_part_strata_on_strata_rawval"
  end
end
