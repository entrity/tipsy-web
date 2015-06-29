class DataForDrinksIngredients < ActiveRecord::Migration
  def up
    execute "insert into drinks_ingredients (drink_id, qty, ingredient_id) select s.drink_id, s.amount, s.ingredient_id from servings as s"
    execute "drop table servings"
  end
end
