class Drink < ActiveRecord::Base
  has_many :drink_ingredients, dependent: :destroy
  has_many :ingredients, through: :drink_ingredients
end
