class Ingredient < ActiveRecord::Base
  include FuzzyFindable
  
  belongs_to :canonical, class_name:'Ingredient'
  belongs_to :revision

  has_many :drink_ingredients, dependent: :destroy
  has_many :drinks, through: :drink_ingredients
  has_many :revisions, class_name:'IngredientRevision', inverse_of: :ingredient

  before_update -> { self.canonical_id = nil if canonical_id == id }

end
