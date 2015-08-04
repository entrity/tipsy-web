class DataSwapDrinksRequiredIngredientIdsForCanonicalOnes < ActiveRecord::Migration
  def up
    execute "UPDATE drinks SET required_canonical_ingredient_ids = (SELECT ARRAY_AGG(ingredients.canonical_id) FROM ingredients INNER JOIN drinks_ingredients ON ingredient_id = ingredients.id WHERE drink_id = drinks.id)"
  end

  def down
    execute "UPDATE drinks SET required_canonical_ingredient_ids = (SELECT ARRAY_AGG(ingredients.id) FROM ingredients INNER JOIN drinks_ingredients ON ingredient_id = ingredients.id WHERE drink_id = drinks.id)"
  end

end
