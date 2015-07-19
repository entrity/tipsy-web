class Review < ActiveRecord::Base
  POINTS_TO_CLOSE = 4

  belongs_to :contributor, class_name: 'User'
  belongs_to :reviewable, polymorphic: true

  has_many :votes, class_name: 'ReviewVotes'

  validates :contributor, presence: true

  default_scope { where(open:true) }

  scope :open, -> user { where(open:true).where('contributor_id != ?', user.id).where('NOT (? = ANY(flagger_ids))', user.id) }

  def award_points
    if points == 0
      raise 'Points are not to be awarded when Review.points is zero'
    end
    operator = points > 0 ? '>' : '<'
    votes.where("points #{operator} 0").each do |vote|
      vote.award_points!
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
      if points > 0
        reviewable.publish!
      else
        reviewable.update_attributes! status:status
      end
      award_points
    end
  end

end
