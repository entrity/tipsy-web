class AddTimestampAndPointableToPointDistributions < ActiveRecord::Migration
  def change
    change_table :point_distributions do |t|
      t.integer :pointable_id
      t.string :pointable_type
      t.timestamp :created_at
    end
  end
end
