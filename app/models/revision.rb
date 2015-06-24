class Revision < ActiveRecord::Base
  include Flaggable

  belongs_to :user
  belongs_to :revisable, polymorphic: true

  has_one :review, as: :reviewable, dependent: :destroy

  has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable

  validates :user, presence: true
  validates :revisable, presence: true
  validates :text, presence: true

  def publishable_without_review?
    case reviewable_type
    when 'Revision', 'Photo'
      false
    when 'Comment'
      true
    end
  end

  # Set status, and rollback flaggable's revision
  def unpublish!
    update_attributes! status:Flaggable::NEEDS_REVIEW
    replacement = revisable.revisions.where(status:Flaggable::APPROVED).last
    revisable.update_attributes! revision:replacement, flag_pts:0, flagger_ids:[]
  end

end
