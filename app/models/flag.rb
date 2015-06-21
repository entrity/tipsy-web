class Flag < ActiveRecord::Base
  belongs_to :user
  belongs_to :flaggable, polymorphic: true

  validates :user, presence: true
  validates :flaggable, presence: true

  before_create -> { self.points = user.try(:log_points) }
end
