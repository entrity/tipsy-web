class AddIngredientIdsToDrinks < ActiveRecord::Migration
  def change
    add_column :drinks, :ingredient_ids, :integer, array: true
  end
end
