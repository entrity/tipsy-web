class CreateFlaggables < ActiveRecord::Migration
  def change

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
      t.integer :status, :default => 1, :limit => 1
      t.timestamps
    end
    add_index :comments, [:commentable_id, :commentable_type]
    add_index :comments, :user_id

    create_table :flags do |t|
      t.integer :user_id
      t.integer :flaggable_id
      t.string  :flaggable_type # revision, comment, photo
      t.integer :flag_bits, :limit => 1, :default => 0
      t.integer :flag_pts, :limit => 1, :null => false
      t.timestamp :created_at
    end

    create_table :revisions do |t|
      t.integer :user_id
      t.integer :revisable_id
      t.string  :revisable_type # drink, ingredient
      t.text    :text
      t.integer :flag_pts, :limit => 1, :default => 0
      t.integer :status, :default => 0, :limit => 1
      t.timestamps
    end
    add_index :revisions, [:revisable_id, :revisable_type]
    add_index :revisions, :user_id
    
    create_table :reviews do |t|
      t.integer :reviewable_id
      t.string  :reviewable_type # revision, comment, photo
      t.boolean :open, :default => true
      t.integer :contributor_id
      t.integer :points, :limit => 1, :default => 0
      t.integer :flagger_ids, array: true, default: []
      t.timestamp :created_at
    end
    add_index :reviews, [:reviewable_id, :reviewable_type]

    create_table :review_votes do |t|
      t.integer :user_id
      t.integer :review_id
      t.integer :points, :limit => 1, :null => false
      t.timestamp :created_at
    end

  end
end
