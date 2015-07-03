class Revision < ActiveRecord::Base
  include Flaggable

  belongs_to :user
  belongs_to :drink
  belongs_to :parent, class_name: 'Revision'

  has_one :review, -> { order id:'DESC' }, as: :reviewable, dependent: :destroy

  has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable

  validates :user, presence: true
  validates :drink, presence: true
  validates :ingredients, presence: true

  # Set status and rollback revisable's revision
  def unpublish!
    update_attributes! status:Flaggable::NEEDS_REVIEW
  end

end
