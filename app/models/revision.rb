class Revision < ActiveRecord::Base
  include HasFlagPts

  belongs_to :user
  belongs_to :flaggable, polymorphic: true

  validates :user, presence: true
  validates :flaggable, presence: true
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
    replacement = flaggable.revisions.where(status:Flaggable::APPROVED).last
    flaggable.update_attributes! revision:replacement
  end

end
