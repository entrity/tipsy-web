class Flag < ActiveRecord::Base
  SPAM       = (1<<0)
  INDECENT   = (1<<1)
  COPYRIGHT  = (1<<2)

  belongs_to :user
  belongs_to :flaggable, polymorphic: true

  scope :for_user_photos_comments, -> user_id, photo_ids, comment_ids {
    stmt =
    if photo_ids.present? || comment_ids.present?
      conditions = []
      conditions.push("(flaggable_type = 'Photo' AND flaggable_id IN (%s))" % photo_ids.join(',')) if photo_ids.present?
      conditions.push("(flaggable_type = 'Comment' AND flaggable_id IN (%s))" % comment_ids.join(',')) if comment_ids.present?
      "user_id = %d AND (%s)" % [user_id, conditions.join(' OR ')]
    else
      'FALSE'
    end
    where(stmt)
  }

  validates :user, presence: true, uniqueness:{scope: :flaggable}
  validates :flaggable, presence: true
  validates :description, presence: true

  before_create -> { self.flag_pts = user.try(:log_points) }
  
  def copyright_flag?
    (flag_bits & COPYRIGHT) != 0
  end

  def indecent_flag?
    (flag_bits & INDECENT) != 0
  end

  def spam_flag?
    (flag_bits & SPAM) != 0
  end
end
