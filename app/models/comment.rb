class Comment < ActiveRecord::Base
  include Flaggable
  include Votable

  belongs_to :user
  belongs_to :drink

  validates :user, presence: true
  validates :drink, presence: true

  # @override Votable
  def distribute_vote_points(prev_sign, sign)
    # noop
  end

  def set_user user
    self.user_id = user.id
    self.user_name = user.nickname
    self.user_name = user.name if user_name.blank?
    self.user_name = "User ##{user.id}" if user_name.blank?
    self.user_avatar = user.photo.url(:tiny)
  end

end
