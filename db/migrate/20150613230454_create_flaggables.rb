class CreateFlaggables < ActiveRecord::Migration
  def change
    rename_column :drinks, :instructions, :text
    rename_column :ingredients, :description, :text

    change_table :users do |t|
      t.integer :helpful_flags, :default => 0
      t.integer :unhelpful_flags, :default => 0
      t.integer :majority_review_votes, :default => 0
      t.integer :minority_review_votes, :default => 0
      t.integer :points, :default => 0
    end

    create_table :comments do |t|
      t.integer :user_id
      t.integer :commentable_id
      t.string  :commentable_type # drink, ingredient
      t.text    :text
      t.integer :flag_pts, :limit => 1, :default => 0
      t.integer :flagger_ids, array: true, default: []
      t.integer :status, :default => 0, :limit => 1
      t.timestamps
    end
    add_index :comments, [:commentable_id, :commentable_type]
    add_index :comments, :user_id

    create_table :flags do |t|
      t.integer :user_id
      t.integer :flaggable_id
      t.string  :flaggable_type # revision, comment, photo
      t.integer :points, :limit => 1, :null => false
      t.timestamp :created_at
    end

    create_table :revisions do |t|
      t.integer :user_id
      t.integer :flaggable_id
      t.string  :flaggable_type # drink, ingredient
      t.text    :text
      t.integer :flag_pts, :limit => 1, :default => 0
      t.integer :flagger_ids, array: true, default: []
      t.integer :status, :default => 0, :limit => 1
      t.timestamps
    end
    add_index :revisions, [:flaggable_id, :flaggable_type]
    add_index :revisions, :user_id
    
    create_table :reviews do |t|
      t.integer :reviewable_id
      t.string  :reviewable_type # revision, comment, photo
      t.boolean :open, :default => true
      t.integer :points, :limit => 1, :default => 0
      t.timestamp :created_at
    end
    add_index :reviews, [:reviewable_id, :reviewable_type]

    create_table :review_votes do |t|
      t.integer :user_id
      t.integer :review_id
      t.integer :points, :limit => 1, :null => false
      t.timestamp :created_at
    end

    change_table :drinks do |t|
      t.integer :flag_pts, :limit => 1, :default => 0
      t.integer :revision_id
    end
    change_table :ingredients do |t|
      t.integer :flag_pts, :limit => 1, :default => 0
      t.integer :revision_id
    end
  end
end
