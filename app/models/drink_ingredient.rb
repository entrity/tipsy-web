class DrinkIngredient < ActiveRecord::Base
  self.set_table_name 'drinks_ingredients'
  belongs_to :drink
  belongs_to :ingredient
end
