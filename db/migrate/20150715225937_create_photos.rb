class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.integer :drink_id
      t.integer :upvote_ct, default: 0, limit: 2
      t.integer :dnvote_ct, default: 0, limit: 2
      t.integer :score, default: 0, limit: 2
      t.integer :flag_pts, default: 0, limit: 1
      t.integer :status, default: 1, limit: 1
      t.timestamp :created_at
      t.integer :user_id
      t.string  :alt
      t.attachment :file
    end
    add_index :photos, [:drink_id, :status]
    add_attachment :users, :photo
  end
end
