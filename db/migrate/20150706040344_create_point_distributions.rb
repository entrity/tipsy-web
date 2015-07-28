class CreatePointDistributions < ActiveRecord::Migration
  def change
    create_table :point_distributions do |t|
      t.integer :user_id
      t.integer :points
      t.integer :category_id
    end
  end
end
