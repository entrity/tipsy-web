class IngredientRevision < ActiveRecord::Base
  include Flaggable
  include Patchable

  publishable_field :name
  publishable_field :canonical_id
  publishable_field :description, patch: true

  belongs_to :user
  belongs_to :ingredient
  belongs_to :parent, class_name: 'IngredientRevision'

  has_one :review, -> { order id:'DESC' }, as: :reviewable, dependent: :destroy

  has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable

  alias_attribute :patchable, :ingredient

  validates :name, presence: true
  validates :user, presence: true

  def publish!
    self.patchable = self.ingredient = Ingredient.new unless ingredient
    user.increment_revision_ct! unless flags.limit(1).count > 0 # If any flags are present, then this has already been published once and doesn't merit distribution of counts/points
    super
    if canonical_id != prev_canonical_id
      prev_val = prev_canonical_id || ingredient_id
      curr_val = canonical_id || ingredient_id
      # Update denormalized canonical ingredient ids on drinks
      self.class.connection.execute("UPDATE drinks
        SET required_canonical_ingredient_ids = ARRAY_REPLACE(required_canonical_ingredient_ids, #{prev_val}, #{curr_val})
        WHERE #{prev_val} = ANY(required_canonical_ingredient_ids)")
      # Update canonical ingredient ids on drinks_ingredients
      self.class.connection.execute("UPDATE drinks_ingredients
        SET canonical_id = #{curr_val}
        WHERE ingredient_id = #{ingredient_id}")
    end
  end

end
