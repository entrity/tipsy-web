class Revision < ActiveRecord::Base
  include Flaggable
  include Patchable

  publishable_field :description,  patch: true
  publishable_field :instructions, patch: true, prev_key: :prev_instruction
  publishable_field :calories
  publishable_field :prep_time
  publishable_field :name, allow_nil: false
  publishable_field -> dummy_arg { ingredients.length }, foreign_key: :ingredient_ct

  belongs_to :user
  belongs_to :drink
  belongs_to :parent, class_name: 'Revision'

  has_one :review, -> { order id:'DESC' }, as: :reviewable, dependent: :destroy

  has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable

  alias_attribute :base_id, :parent_id
  alias_attribute :patchable, :drink

  validates :user, presence: true

  before_save -> { self.ingredients = ingredients.map(&:as_json) }, if: :ingredients
  before_save -> { self.prev_ingredients = prev_ingredients.map(&:as_json) }, if: :prev_ingredients

  def publish!
    self.ingredients ||= []
    if drink_id.nil? # if there is no drink_id, this revision represents a user-created drink that doesn't exist yet
      self.drink = Drink.create(user_id:user_id, name:name)
    end
    drink.required_ingredient_ids = ingredients.select{|ing| !ing['optional'] }.map{|ing| ing['id'] }
    user.increment_revision_ct! unless flags.limit(1).count > 0 # If any flags are present, then this has already been published once and doesn't merit distribution of counts/points
    # Create/destroy added/removed ingredients
    if drink.revision.nil?
      ingredients.each{|ing| drink.ingredients.create!(ing) }
    else
      prev_ingredients ||= drink.ingredients || parent.try(:ingredients)
      deled_ingredients = Array.wrap(prev_ingredients) - Array.wrap(ingredients)
      added_ingredients = Array.wrap(ingredients) - Array.wrap(prev_ingredients)
      if deled_ingredients.present?
        del_ingredient_ids = deled_ingredients.map{|ing| ing['ingredient_id'] }
        DrinkIngredient.where(drink_id:drink_id, ingredient_id:del_ingredient_ids).delete_all
      end
      if added_ingredients.present?
        added_ingredients.each{|ing| DrinkIngredient.create!(ing.merge(drink_id:drink_id)) }
      end
    end
    super
  end

end
