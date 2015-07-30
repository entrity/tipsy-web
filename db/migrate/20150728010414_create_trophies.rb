class CreateTrophies < ActiveRecord::Migration
  def change
    create_table :trophies do |t|
      t.integer :user_id, null: false
      t.integer :category_id, null: false
      t.timestamp :created_at, null: false
    end

    change_table :users do |t|
      t.integer :gold_trophy_ct, default: 0
      t.integer :silver_trophy_ct, default: 0
      t.integer :bronze_trophy_ct, default: 0
      t.integer :comment_ct, default: 0
      t.integer :revision_ct, default: 0
      t.integer :photo_ct, default: 0
    end

    change_table :flags do |t|
      t.integer :tallied, boolean: false
    end

    change_table :drinks do |t|
      t.integer :user_id
    end
  end
end
