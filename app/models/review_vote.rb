class ReviewVote < ActiveRecord::Base
  belongs_to :review
  belongs_to :user, as: :review_votes

  validates :user, presence: true
  validates :review, presence: true
  validates :points, presence: true

  # Update review
  after_create -> { review.vote!(points) }

end
