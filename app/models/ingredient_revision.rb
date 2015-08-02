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
  validates :ingredient, presence: true

  def publish!
    user.increment_revision_ct! unless flags.limit(1).count > 0 # If any flags are present, then this has already been published once and doesn't merit distribution of counts/points
    super
  end

end
