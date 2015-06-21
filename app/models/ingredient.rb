class Ingredient < ActiveRecord::Base
  include FuzzyFindable
  include Revisable
  include Flaggable
  
  has_many :drink_ingredients, dependent: :destroy
  has_many :drinks, through: :drink_ingredients
end
