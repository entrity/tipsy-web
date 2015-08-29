class DrinkIngredient < ActiveRecord::Base
  self.table_name = 'drinks_ingredients'
  belongs_to :drink, inverse_of: :ingredients
  belongs_to :ingredient
  delegate :name, to: :ingredient
  delegate :name, to: :drink, prefix: true
  delegate :url_path, to: :ingredient
end
