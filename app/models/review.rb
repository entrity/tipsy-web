class Review < ActiveRecord::Base
  POINTS_TO_CLOSE = 4

  belongs_to :contributor, class_name: 'User'
  belongs_to :reviewable, polymorphic: true

  has_many :votes, class_name: 'ReviewVote'

  validates :contributor, presence: true

  default_scope { where(open:true) }

  scope :open, -> user { where(open:true).where('contributor_id != ?', user.id).where('NOT (? = ANY(flagger_ids))', user.id) }

  def award_points
    if points == 0
      raise 'Points are not to be awarded when Review.points is zero'
    end
    # Increment user vote cts; award points; award trophies
    votes.each do |vote|
      if (vote.points <=> 0) == (points <=> 0)
        PointDistribution.award_winning_vote(vote.user_id, vote)
        vote.user.increment_majority_votes!
      else
        vote.user.increment_minority_votes!
      end
    end
    # Increment flag cts and award trophies
    flags = reviewable.flags.where(tallied: false)
    flags.update_all tallied: true
    flags.each do |flag|
      if points > 0
        flag.user.increment_helpful_flags!
      else
        flag.user.increment_unhelpful_flags!
      end
    end
  end

  def flags
    reviewable.try(:flags)
  end

  # Returns a Review if successful, else nil
  def self.next! user
    res = connection.raw_connection.exec_params(%Q(UPDATE #{table_name} topquery
      SET last_hold = current_timestamp, last_hold_user_id = $2
      FROM (
        SELECT id FROM reviews
        WHERE (last_hold IS NULL OR last_hold < $1 OR last_hold_user_id = $2)
        AND open IS TRUE
        AND contributor_id != $2
        AND NOT $2 = ANY(flagger_ids)
        LIMIT 1
        FOR UPDATE
      ) subquery
      WHERE topquery.id = subquery.id
      RETURNING *),
    [5.minutes.ago, user.id])
    if res.cmd_tuples == 1
      Review.new(res.first)
    end
  end

  def vote! vote
    # Update points and open fields
    conn = self.class.connection.raw_connection
    conn.exec_params(
      %Q(UPDATE #{self.class.table_name}
        SET
          points = points + $1,
          open = points + $1 < abs(#{POINTS_TO_CLOSE}),
          flagger_ids = array_append(flagger_ids, $3) 
        WHERE id = $2), [vote.points, id, vote.user_id]
    )
    # If this Review is closed, set status of reviewable, distribute points to voters
    unless reload.open
      reviewable.update_attributes! status:status
      reviewable.publish! if points > 0
      award_points
    end
  end

  private

    def status
      if points > 0
        Flaggable::APPROVED
      elsif points < 0
        Flaggable::REJECTED
      else
        Flaggable::NEEDS_REVIEW
      end
    end

end
