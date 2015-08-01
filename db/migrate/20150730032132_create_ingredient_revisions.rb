class CreateIngredientRevisions < ActiveRecord::Migration
  def change
    change_table :ingredients do |t|
      t.integer :canonical_id
    end
    add_index :ingredients, [:canonical_id, :id]
    create_table :ingredient_revisions do |t|
      t.integer :user_id
      t.integer :ingredient_id
      t.integer :parent_id
      t.string  :name
      t.text    :description
      t.text    :prev_description
      t.integer :canonical_id
      t.integer :prev_canonical_id
      t.integer :flag_pts, default: 0, limit: 1
      t.integer :status, default: 0, limit: 1
      t.timestamp :created_at
    end
    add_index :ingredient_revisions, [:ingredient_id, :user_id, :id]
  end
end
