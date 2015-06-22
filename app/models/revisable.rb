module Revisable

  def self.included(base)
    unless base.attribute_method?(:text)
      raise "No text column on class #{base.name}"
    end
    base.belongs_to :revision, dependent: :destroy, inverse_of: :flaggable
    base.has_many :revisions, as: :flaggable, dependent: :destroy
  end

  # Sets flags on self.revision
  # Saves self.revision but does not save self
  def rollback_revision
    # Copy data onto revision
    flagger_ids.each do |id|
      revision.flagger_ids << id
    end
    # revision.flag_pts = revision.flagger_ids.length
    revision.status = Flaggable::NEEDS_REVIEW
    revision.flaggable = self
    revision.save!
    # Change self.revision
    self.revision = Revision.where(status:Flaggable::APPROVED).last
  end

end
