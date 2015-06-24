module Flaggable
  FLAG_PTS_LIMIT = 3
  # Values for status field
  REJECTED     = -1
  NEEDS_REVIEW = 0
  APPROVED     = 1

  def self.included(base)
    base.include HasFlagPts
    unless base.attribute_method?(:status)
      raise "No status column on class #{base.name}"
    end
    base.has_one :review, as: :reviewable, dependent: :destroy
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
    # Set flag_pts & flagger_ids
    increment_flag_points!(flag.flag_pts, flag.user_id)
    # Flag Revisable (if Revision)
    revisable.increment_flag_points!(flag.flag_pts, flag.user_id) if is_a?(Revision)
    # Unpublish (revision or self) if there are enough flag_pts to warrant a Review (and there isn't already an open Review for this contribution)
    if create_review_if_needed
      review.update_attributes(
        contributor_id: user_id,
        flag_bits:      flags.pluck(:flag_bits).reduce(:|),
        flagger_ids:    flagger_ids,
      )
      unpublish! # flag_owner could be nil if a bug led to a Revisable being flagged even if it lacks a Revision
    end
    true
  end

  private

    # @return - boolean for whether a Review was created in the db
    def create_review_if_needed
      res = self.class.connection.raw_connection.exec_params(
        "select create_review_if_needed($1, $2, $3)",
        [self.class.table_name, id, self.class.name]
      )
      return res.getvalue(0,0) == 't'
    end

  protected

    # This is overridden for Revision
    def unpublish!
      update_attributes status:NEEDS_REVIEW
    end

end
