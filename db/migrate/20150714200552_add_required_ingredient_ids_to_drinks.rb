class AddRequiredIngredientIdsToDrinks < ActiveRecord::Migration
  def change
    add_column :drinks, :required_ingredient_ids, :integer, array: true
  end
end
