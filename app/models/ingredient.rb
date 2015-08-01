class Ingredient < ActiveRecord::Base
  include FuzzyFindable
  
  belongs_to :canonical, class_name:'Ingredient'
  belongs_to :revision, inverse_of: :ingredient

  has_many :drink_ingredients, dependent: :destroy
  has_many :drinks, through: :drink_ingredients

  before_update -> { self.canonical_id = nil if canonical_id == id }

end
