class DrinkIngredient < ActiveRecord::Base
  self.table_name = 'drinks_ingredients'
  belongs_to :drink
  belongs_to :ingredient
  delegate :name, to: :ingredient
  delegate :name, to: :drink, prefix: true
end
