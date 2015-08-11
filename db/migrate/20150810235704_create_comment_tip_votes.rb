class CreateCommentTipVotes < ActiveRecord::Migration
  def change
    create_table :comment_tip_votes do |t|
      t.integer :user_id, null: false
      t.integer :comment_id, null: false
      t.timestamp :created_at
    end
    add_index :comment_tip_votes, [:user_id, :comment_id]
  end
end
