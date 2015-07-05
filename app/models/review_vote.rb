class ReviewVote < ActiveRecord::Base
  belongs_to :review
  belongs_to :user, inverse_of: :review_votes

  validates :user, presence: true
  validates :review, presence: true, uniqueness: {scope: :user}
  validates :points, presence: true

  # Update review
  after_create -> { review.vote!(self) }

  def unique?
    self.class.where(user_id:user_id, review_id:review_id).limit(1).count != 0
  end

end
