module Flaggable
  FLAG_PTS_LIMIT = 3
  # Values for status field
  REJECTED     = -1
  NEEDS_REVIEW = 0
  APPROVED     = 1
  # Values for db response in #flag!
  DB_INITIAL = 0
  DB_FLAG_INSERTED = 1
  DB_REVIEW_INSERTED = 2

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
    db_status_string = res.getvalue(0,0) # Indicates whether a review was created
    unless db_status_string =~ /\d+/
      raise TipsyException.new db_flag_err_string(db_status_string)
    end
    db_status = db_status_string.to_i
    if db_status < DB_INITIAL || db_status > DB_REVIEW_INSERTED
      raise TipsyException.new db_flag_err_string(db_status_string)
    end
    unpublish! if db_status >= DB_REVIEW_INSERTED
    # Indicates whether a Flag was created
    return db_status >= DB_FLAG_INSERTED
  end

  # Set status to NEEDS_REVIEW, which should create a review in a db callback
  def unpublish!
    update_attributes! status:NEEDS_REVIEW
  end

  private

    def db_flag_err_string db_status
      "Unexpected output from db in #{self.class.name}#flag! \"#{db_status}\" for #{inspect}"
    end

end
