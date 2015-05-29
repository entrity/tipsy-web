class Drink < ActiveRecord::Base
  has_many :ingredients, class_name:'DrinkIngredient', dependent: :destroy
end
