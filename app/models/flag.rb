class Flag < ActiveRecord::Base
  SPAM       = (1<<0)
  INDECENT   = (1<<1)
  COPYRIGHT  = (1<<2)

  belongs_to :user
  belongs_to :flaggable, polymorphic: true

  validates :user, presence: true
  validates :flaggable, presence: true

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
