class AddAuthorPrepTimeCaloriesToDrinks < ActiveRecord::Migration
  def change
    change_table :drinks do |t|
      t.integer :author_id
      t.integer :calories, limit:2
      t.text :prep_time
    end
  end
end
