class AddLastHoldToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :last_hold, :timestamp
    add_column :reviews, :last_hold_user_id, :integer
    add_index :reviews, [:open, :contributor_id]
  end
end
