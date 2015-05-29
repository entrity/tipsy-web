class Ingredient < ActiveRecord::Base
  has_many :drink_ingredients, dependent: :destroy
  has_many :drinks, through: :drink_ingredients
end
