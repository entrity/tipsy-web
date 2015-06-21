module Flaggable
  FLAG_PTS_LIMIT = 3
  # Values for status field
  REJECTED     = -1
  NEEDS_REVIEW = 0
  APPROVED     = 1

  def self.included(base)
    base.include HasFlagPts
    unless base.attribute_method?(:status) || base < Revisable
      raise "No status column on class #{base.name}"
    end
    unless base == Revision
      base.has_one :review, as: :reviewable, dependent: :destroy
    end
    base.has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable
  end

  # Create flag
  # If Revisable: set flag_pts & flagger_ids on current revision
  # Set flag_pts & flagger_ids
  # If overflagged?:
  #  - create Review
  #  - unpublish (not Revisable) or rollback (Revisable)
  def flag! user
    # Create flag
    flag = flags.create!(user:user)
    # Flag revision (if Revisable)
    revision.increment_flag_points!(flag.points, flag.user_id) if revisable?
    # Set flag_pts & flagger_ids
    increment_flag_points!(flag.points, flag.user_id)
    if overflagged?
      create_review!
      # Unpublish (revision or self)
      unpublishable = revisable? ? revision : self
      unpublishable.unpublish! # unpublishable could be nil if a bug led to a Revisable being flagged even if it lacks a Revision
    end
    true
  end

  private

    def overflagged?
      flag_pts > FLAG_PTS_LIMIT
    end

    # @return whether this object includes Revisable
    # If so, this is a Drink, Ingredient, etc. it has a revision 
    # Otherwise, this is a Comment, Photo, etc.
    def revisable?
      self.class < Revisable
    end

    def unpublish!
      self.status = NEEDS_REVIEW
      create_review! points:0, open:true
    end

end
