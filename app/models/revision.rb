class Revision < ActiveRecord::Base
  include Flaggable

  belongs_to :user
  belongs_to :drink
  belongs_to :base, class_name: 'Revision', foreign_key: :parent_id

  has_one :review, -> { order id:'DESC' }, as: :reviewable, dependent: :destroy

  has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable

  alias_attribute :base_id, :parent_id

  validates :user, presence: true
  validates :drink, presence: true

  before_save -> { self.ingredients = ingredients.map(&:as_json) }, if: :ingredients
  before_save -> { self.prev_ingredients = prev_ingredients.map(&:as_json) }, if: :prev_ingredients

  def publish!
    update_attributes! status:Flaggable::APPROVED
    required_ingredient_ids = ingredients.select{|ing| !ing['optional'] }.map{|ing| ing['id'] }
    if drink.revision.nil?
      drink.update_attributes!(
        revision_id:id,
        description:description,
        instructions:instructions,
        calories:calories,
        prep_time:prep_time,
        name:name,
        ingredient_ct:ingredients.length,
        required_ingredient_ids:required_ingredient_ids,
      )
      ingredients.each{|ing| drink.ingredients.create!(ing) }
    else
      if created_at >= drink.revision.created_at
        drink.revision_id = id
        drink.calories = calories
        drink.prep_time = prep_time
        drink.name = name
      end
      # Patch description
      prev_description ||= base.try(:description) || drink.description || ''
      drink.description = patch(prev_description, description||'', drink.description)
      # Patch instructions
      prev_instruction ||= base.try(:instructions) || drink.instructions || ''
      drink.instructions = patch(prev_instruction, instructions||'', drink.instructions)
      # Add/Delete selected ingredients
      prev_ingredients ||= base.try(:ingredients) || drink.ingredients
      deled_ingredients = Array.wrap(prev_ingredients) - Array.wrap(ingredients)
      added_ingredients = Array.wrap(ingredients) - Array.wrap(prev_ingredients)
      if deled_ingredients.present?
        del_ingredient_ids = deled_ingredients.map{|ing| ing['ingredient_id'] }
        DrinkIngredient.where(drink_id:drink_id, ingredient_id:del_ingredient_ids).delete_all
      end
      if added_ingredients.present?
        added_ingredients.each{|ing| DrinkIngredient.create!(ing.merge(drink_id:drink_id)) }
      end
      # Save drink
      drink.save!
    end
  end

  # Set status and rollback revisable's revision
  def unpublish!
    super
    raise 'to do'
  end

  private

    def patch prev, post, target
      patcher = DiffMatchPatch.new
      patches = patcher.patch_make(prev, post)
      text, results = patcher.patch_apply(patches, target)
      return text
    end

end
