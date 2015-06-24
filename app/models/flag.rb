class Flag < ActiveRecord::Base
  include HasFlagBits

  belongs_to :user
  belongs_to :flaggable, polymorphic: true

  validates :user, presence: true
  validates :flaggable, presence: true

  before_create -> { self.flag_pts = user.try(:log_points) }
end
