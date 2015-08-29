class RequiredCanonicalIngredientIdsOnDrinks < ActiveRecord::Migration
  def change
    rename_column :drinks, :required_ingredient_ids, :required_canonical_ingredient_ids
    add_column :drinks_ingredients, :canonical_id, :integer
  end
end
