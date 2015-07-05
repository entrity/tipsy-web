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
  validates :ingredients, presence: true

  before_save -> { self.ingredients = ingredients.map(&:as_json) }

  # Set status and rollback revisable's revision
  def unpublish!
    update_attributes! status:Flaggable::NEEDS_REVIEW
  end

end
