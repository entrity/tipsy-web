class EnhanceComments < ActiveRecord::Migration
  def change
    remove_index :comments, column: [:commentable_id, :commentable_type]
    change_table :comments do |t|
      t.rename  :commentable_id, :drink_id
      t.integer :tip_pts, default: 0
      t.integer :score, default: 0
      t.integer :upvote_ct, default: 0
      t.integer :dnvote_ct, default: 0
      t.integer :parent_id
      t.string  :user_name
      t.string  :user_avatar
    end
    add_index :comments, [:drink_id, :id]
    reversible do |dir|
      dir.up do
        remove_column :comments, :commentable_type
      end
      dir.down do
        add_column :comments, :commentable_type, :string
      end
    end
  end
end
