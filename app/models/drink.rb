class Drink < ActiveRecord::Base
  include FuzzyFindable

  belongs_to :author, class_name:'User'
  belongs_to :revision
  
  has_many :ingredients, class_name:'DrinkIngredient', dependent: :destroy, foreign_key: :drink_id, inverse_of: :drink
  has_many :revisions, inverse_of: :drink

  # Scope results to Drinks which include all of the indicated ingredients
  scope :for_ingredients, -> ingredient_ids {
    ids = Array.wrap(ingredient_ids).compact
    where_operator = ids.length > 1 ? 'IN' : '='
    joins(:ingredients)
      .where("drinks_ingredients.ingredient_id #{where_operator} (?)", ids)
      .distinct
      .order('ingredient_ct')
  }

  def flag!
    revision.try(:flag!)
  end

  def vote_sum
    up_vote_ct - dn_vote_ct
  end
  
end
