class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer :user_id
      t.integer :votable_id
      t.string :votable_type
      t.integer :sign, limit: 1, default: 0
      t.timestamps null: false
    end

    add_index :votes, [:user_id, :votable_id, :votable_type], name: :index_votes

    add_column :point_distributions, :viewed, :boolean, default: false

    add_index :point_distributions, [:user_id, :pointable_id, :pointable_type], name: :index_point_distributions
    add_index :point_distributions, [:user_id, :viewed, :created_at], name: :index_viewed_point_distributions
  end
end
