class CreateDrinks < ActiveRecord::Migration
  def change
    create_table :drinks do |t|
      t.string :name
      t.integer :abv, limit:2 # alcohol by volume
      t.text :description
      t.text :instructions
      t.float :score, default:0 # average vote
      t.integer :vote_ct, default:0
      t.integer :glass_id, limit:2
      t.string :color
    end
    add_index :drinks, :name
  end
end
