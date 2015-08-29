class AddSortOrderToDrinksIngredients < ActiveRecord::Migration
  def change
    add_column   :drinks_ingredients, :sort, :integer, default: 0
    remove_index :drinks_ingredients, column: [:drink_id]
    add_index    :drinks_ingredients, [:drink_id, :sort]
  end
end
