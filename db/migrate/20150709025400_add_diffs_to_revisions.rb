class AddDiffsToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :prev_description, :text
    add_column :revisions, :prev_instruction, :text
    add_column :revisions, :prev_ingredients, :hstore, array: true
  end
end
