class Drink < ActiveRecord::Base
  include FuzzyFindable
  include Votable

  belongs_to :user, class_name:'User' # author
  belongs_to :revision
  
  has_many :comments, inverse_of: :drink
  has_many :ingredients, class_name:'DrinkIngredient', dependent: :destroy, foreign_key: :drink_id, inverse_of: :drink
  has_many :photos, inverse_of: :drink
  has_many :revisions, inverse_of: :drink

  validates :name, presence: true

  # Scope results to Drinks which include all of the indicated ingredients
  scope :for_ingredients, -> ingredient_ids {
    ids = Array.wrap(ingredient_ids).compact
    where_operator = ids.length > 1 ? 'IN' : '='
    joins(:ingredients)
      .where("drinks_ingredients.ingredient_id #{where_operator} (?)", ids)
      .distinct
      .order('ingredient_ct')
  }

  scope :for_exclusive_ingredients, -> canonical_ingredient_ids {
    first_pass_drink_ids = DrinkIngredient.where(canonical_id:canonical_ingredient_ids).where('optional IS NOT TRUE').distinct.pluck(:drink_id)
    where(id:first_pass_drink_ids).where('required_canonical_ingredient_ids <@ \'{?}\'', Array.wrap(canonical_ingredient_ids).map(&:to_i))
  }

  def flag!
    revision.try(:flag!)
  end

  def top_photo
    @top_photo ||= photos.order(:score).last
  end

  def url_path
    "/recipe/#{id}-#{name.to_s.downcase.gsub(/[\W]+/, '-')}"
  end
  
  def vote_sum
    up_vote_ct - dn_vote_ct
  end

end
