class MigrateIngredientIdsOntoDrinks < ActiveRecord::Migration
  def up
    res = execute "SELECT drink_id, ARRAY_AGG(ingredient_id) AS ingredient_ids FROM drinks_ingredients GROUP BY drink_id"
    res.each do |hash|
      ingredient_ct = hash['ingredient_ids'].scan(/\d+/).size
      execute "UPDATE DRINKS SET ingredient_ids = '#{hash['ingredient_ids']}', ingredient_ct = #{ingredient_ct} WHERE id = #{hash['drink_id']}"
    end
  end
end
