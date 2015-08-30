class Ingredient < ActiveRecord::Base
  include FuzzyFindable
  
  belongs_to :canonical, class_name:'Ingredient'
  belongs_to :revision

  has_many :drink_ingredients, dependent: :destroy
  has_many :drinks, through: :drink_ingredients
  has_many :revisions, class_name:'IngredientRevision', inverse_of: :ingredient

  before_update -> { self.canonical_id = nil if canonical_id == id }

  def self.gin_canonical_id
    @@gin_canonical_id ||= where('name ilike \'gin\'').limit(1).pluck(:canonical_id).first
  end

  def self.vodka_canonical_id
    @@vodka_canonical_id ||= where('name ilike \'vodka\'').limit(1).pluck(:canonical_id).first
  end

  def self.tequila_canonical_id
    @@tequila_canonical_id ||= where('name ilike \'tequila\'').limit(1).pluck(:canonical_id).first
  end

  def self.triple_sec_canonical_id
    @@triple_sec_canonical_id ||= where('name ilike \'triple sec\'').limit(1).pluck(:canonical_id).first
  end

  def url_path
    "/ingredient/#{id}-#{name.to_s.downcase.gsub(/[\W]+/, '-')}.html"
  end

end
