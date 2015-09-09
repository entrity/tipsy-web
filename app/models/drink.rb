class Drink < ActiveRecord::Base
  include FuzzyFindable
  include Votable

  belongs_to :user, class_name:'User' # author
  belongs_to :revision
  
  has_many :comments, inverse_of: :drink
  has_many :ingredients, class_name:'DrinkIngredient', dependent: :destroy, foreign_key: :drink_id, inverse_of: :drink
  has_many :photos, inverse_of: :drink
  has_many :revisions, inverse_of: :drink

  has_one :photo, -> { order('score DESC') }

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
    where("id in #{Drink.ids_for_ingredients_sql(canonical_ingredient_ids)}")
    .where('required_canonical_ingredient_ids <@ \'{?}\'', Array.wrap(canonical_ingredient_ids).map(&:to_i))
  }

  def flag!
    revision.try(:flag!)
  end

  # Find imperfect Drink matches for list of ingredients
  def self.suggestions canonical_ingredient_ids
    canonical_ids_txt = canonical_ingredient_ids.compact.join(',')
    res = connection.execute %Q(SELECT id, name, required_canonical_ingredient_ids, ingredient_ct, prep_time, up_vote_ct,
      ARRAY_LENGTH(
        (SELECT ARRAY_AGG(i_id) FROM UNNEST(required_canonical_ingredient_ids) i_id WHERE i_id IS NOT NULL)
        - ARRAY[#{canonical_ids_txt}]::int[], 1) as distance
      FROM drinks
        WHERE id IN (#{ids_for_ingredients_sql(canonical_ingredient_ids)})
      ORDER BY distance
      LIMIT 100
    )
    res.to_a
  end

  def self.top required_canonical_ingredient_ids=nil, exclude_ids=nil
    out = order('score DESC')
    if exclude_ids.present?
      if exclude_ids.is_a? Array
        out = out.where("id not in (?)", exclude_ids)
      else
        out = out.where("id != ?", exclude_ids)
      end
    end
    if required_canonical_ingredient_ids.present?
      if required_canonical_ingredient_ids.is_a? Array
        out = out.where("required_canonical_ingredient_ids OPERATOR(pg_catalog.@>) ARRAY[?]::int[]", required_canonical_ingredient_ids)
      else
        out = out.where("#{required_canonical_ingredient_ids.to_i} = ANY(required_canonical_ingredient_ids)")
      end
    end
    out
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

  private

    def self.ids_for_ingredients_sql canonical_ingredient_ids
      '(' + DrinkIngredient.where(canonical_id:canonical_ingredient_ids).where('optional IS NOT TRUE').distinct.select(:drink_id).to_sql + ')'
    end

end
