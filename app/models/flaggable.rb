module Flaggable
  FLAG_PTS_LIMIT = 3
  # Values for status field
  REJECTED     = -1
  NEEDS_REVIEW = 0
  APPROVED     = 1

  def self.included(base)
    unless base.attribute_method?(:status)
      raise "No status column on class #{base.name}"
    end
    unless base.attribute_method?(:flag_pts)
      raise "No flag_pts column on class #{base.name}"
    end
    base.has_one :review, as: :reviewable, dependent: :destroy
    base.has_many :flags, as: :flaggable, dependent: :destroy, inverse_of: :flaggable
  end

  # If no Flag for this User and this flaggable exists:
  # - Create Flag
  # - Increment flag_pts
  # - If overflagged? and no open Review for this flaggable exists:
  #   - create Review
  #   - unpublish
  # @return boolean for whether Review was created
  def flag! user, flag_bits
    conn = self.class.connection.raw_connection
    res = conn.exec_params("SELECT flag_#{self.class.table_name}($1, $2, $3, $4, $5, $6, $7)",
      [user.id, id, self.class.name, FLAG_PTS_LIMIT, flag_bits, user.log_points, Time.now]
    )
    case res.getvalue(0,0) # Indicates whether a review was created
    when 't'
      unpublish!
      true
    when 'f'
      false
    else
      raise TipsyError.new "Unexpected output from db in #{self.class.name}#flag! - #{res} for #{inspect}"
    end
  end

  private

    # This is overridden for Revision
    def unpublish!
      update_attributes! status:NEEDS_REVIEW
    end

end
