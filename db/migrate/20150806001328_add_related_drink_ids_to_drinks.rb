class AddRelatedDrinkIdsToDrinks < ActiveRecord::Migration
  def change
    add_column :drinks, :related_drink_ids, :integer, array:true, default:[]
  end
end
