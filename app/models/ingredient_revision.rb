class IngredientRevision < ActiveRecord::Base
  include Flaggable
  include Patchable

  belongs_to :user
  belongs_to :ingredient
  belongs_to :base, class_name: 'IngredientRevision', foreign_key: :parent_id

  has_one :review, -> { order id:'DESC' }, as: :reviewable, dependent: :destroy

  has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable

  validates :name, presence: true
  validates :user, presence: true
  validates :ingredient, presence: true

  def publish!
    super
    user.increment_revision_ct!
    if ingredient.revision.nil?
      ingredient.update_attributes!(
        revision_id:id,
        name:name,
        description:description,
        canonical_id:canonical_id,
      )
    else
      if created_at >= ingredient.revision.created_at
        ingredient.revision_id = id
        ingredient.name = name
        ingredient.canonical_id = canonical_id
      end
      # Patch description
      prev_description ||= base.try(:description) || ingredient.description || ''
      ingredient.description = patch(prev_description, description||'', ingredient.description)
      # Save ingredient
      ingredient.save!
    end
  end

  # Set status and rollback revisable's revision
  def unpublish!
    super
    raise 'to do'
  end

end
