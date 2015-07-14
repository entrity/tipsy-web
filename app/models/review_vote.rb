class ReviewVote < ActiveRecord::Base
  belongs_to :review
  belongs_to :user, inverse_of: :review_votes

  validates :user, presence: true
  validates :review, presence: true, uniqueness: {scope: :user}
  validates :points, presence: true

  # Update review
  after_create -> { review.vote!(self) }

  def award_points!
    unless points_awarded
      conn = self.class.connection.raw_connection
      res = conn.exec "UPDATE #{self.class.table_name} SET points_awarded = TRUE WHERE id = #{id} AND points_awarded = FALSE"
      PointDistribution.award_winning_vote(user_id, self) if res.cmd_tuples > 0
    end
  end

  def unique?
    self.class.where(user_id:user_id, review_id:review_id).limit(1).count != 0
  end

end
