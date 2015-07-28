class AddCameronsFieldsToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :nickname
      t.text :bio
      t.string :twitter
      t.string :location
    end
  end
end
