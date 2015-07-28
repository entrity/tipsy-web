class JoinDrinksIngredients < ActiveRecord::Migration
  def change
    create_table :drinks_ingredients, id:false do |t|
      t.references :drink
      t.references :ingredient
      t.string :qty
      t.boolean :optional, default:false
    end
    add_index :drinks_ingredients, :drink_id
    add_index :drinks_ingredients, :ingredient_id
  end
end
