class Drink < ActiveRecord::Base
  include FuzzyFindable
  has_many :ingredients, class_name:'DrinkIngredient', dependent: :destroy

  # Scope results to Drinks which include all of the indicated ingredients
  scope :for_ingredients, -> ingredient_ids {
    ids = Array.wrap(ingredient_ids).compact
    where_operator = ids.length > 1 ? 'IN' : '='
    joins(:ingredients)
      .where("drinks_ingredients.ingredient_id #{where_operator} (?)", ids)
      .distinct
      .order('ingredient_ct')
  }
end
